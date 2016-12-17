require 'spec_helper'

describe Feed do
  describe 'slug' do
    subject { Feed.new(url: 'http://www.example.com/rss') }

    it 'should calculate slug before creating' do
      subject.name = 'Feed RSS de ejemplo'
      expect(subject.slug).to be_nil

      expect(subject.save).to be_truthy
      expect(subject.slug).to eq 'feed-rss-de-ejemplo'
    end

    it 'should not update slug on updates' do
      subject.name = 'Feed RSS de ejemplo'
      subject.save!

      subject.name = 'Otro nombre'

      expect(subject.save).to be_truthy
      expect(subject.slug).to eq 'feed-rss-de-ejemplo'
    end

    it 'should validate uniqueness of slug' do
      existing_feed = Feed.create(url: 'http://www.foo.com/rss', name: 'Un feed')
      expect(existing_feed.slug).to eq 'un-feed'

      subject.name = 'UN FEED'
      subject.slug = 'un-feed'

      expect(subject).not_to be_valid
      expect(subject.errors[:slug]).to include 'is already taken'
    end

    it 'should validate uniqueness of url' do
      existing_feed = Feed.create(url: 'http://www.example.com/rss', name: 'Un feed')
      subject.name = 'otro feed'

      expect(subject).not_to be_valid
      expect(subject.errors[:url]).to include 'is already taken'
    end
  end

  describe '#fetch_and_publish_new!' do
    let(:indexador_host) { 'indexador.amviar.org.ar' }
    let(:indexador_port) { '443' }

    let(:url) { 'http://www.example.com/rss' }
    let(:rss_feed) { double(entries: rss_entries) }
    let(:rss_entries) do
      [
        double(last_modified: DateTime.now - 1.day, title: 'Un articulo', content: 'Este es un articulo', url: 'http://www.example.com/un-articulo', author: 'El Autor', published: DateTime.now - 1.day),
        double(last_modified: DateTime.now - 1.hour, title: 'Otro articulo', content: 'Este es otro articulo', url: 'http://www.example.com/otro-articulo', author: 'Otro Autor', published: DateTime.now - 2.hour),
      ]
    end

    subject { Feed.new(url: url, name: 'Feed RSS') }

    before :each do
      allow(Feedjira::Feed).to receive(:fetch_and_parse).with(url).and_return(rss_feed)
    end

    around :each do |example|
      previous_indexador_host = ENV['INDEXADOR_HOST']
      previous_indexador_port = ENV['INDEXADOR_PORT']

      ENV['INDEXADOR_HOST'] = indexador_host
      ENV['INDEXADOR_PORT'] = indexador_port

      example.run

      ENV['INDEXADOR_HOST'] = previous_indexador_host
      ENV['INDEXADOR_PORT'] = previous_indexador_port
    end

    context 'last_fetch_at is nil' do
      it 'should call new content endpoint on Indexador for each entry' do
        req = double
        allow(Net::HTTP::Post).to receive(:new).and_return(req)
        rss_entries.each do |entry|
          expect(req).to receive(:body=).with({title: entry.title, body: entry.content, url: entry.url, creator: entry.author, published_at: entry.published, source: 'rss'}.to_json)
        end
        http_client = double
        expect(Net::HTTP).to receive(:start).twice.with(indexador_host, indexador_port).and_yield(http_client).and_return(double)
        expect(http_client).to receive(:request).twice.with(req)

        subject.fetch_and_publish_new!
      end

      it 'should update last_fetch_at' do
        req = double
        allow(Net::HTTP::Post).to receive(:new).and_return(req)
        rss_entries.each do |entry|
          expect(req).to receive(:body=).with({title: entry.title, body: entry.content, url: entry.url, creator: entry.author, published_at: entry.published, source: 'rss'}.to_json)
        end
        http_client = double
        expect(Net::HTTP).to receive(:start).twice.with(indexador_host, indexador_port).and_yield(http_client).and_return(double)
        expect(http_client).to receive(:request).twice.with(req)

        Timecop.freeze(now = DateTime.now - 10.minutes) do
          subject.fetch_and_publish_new!
        end

        subject.reload
        expect(subject.last_fetch_at.to_i). to eq now.to_i
      end
    end

    context 'last_fetch_at set' do
      before :each do
        subject.last_fetch_at = DateTime.now - 10.hours
      end

      it 'should not send old content to Indexador' do
        req = double
        allow(Net::HTTP::Post).to receive(:new).and_return(req)
        expect(req).to receive(:body=).with({title: rss_entries.last.title, body: rss_entries.last.content, url: rss_entries.last.url, creator: rss_entries.last.author, published_at: rss_entries.last.published, source: 'rss'}.to_json)
        http_client = double
        expect(Net::HTTP).to receive(:start).with(indexador_host, indexador_port).and_yield(http_client).and_return(double)
        expect(http_client).to receive(:request).with(req)

        subject.fetch_and_publish_new!
      end
    end
  end
end
