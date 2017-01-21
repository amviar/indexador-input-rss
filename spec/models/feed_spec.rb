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
    let(:indexador_scheme) { 'https' }
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

    let(:client_id) { 'a-client-id' }
    let(:secret) { 'a-secret' }
    let(:oauth_client) { double }
    let(:access_token) { double }

    subject { Feed.new(url: url, name: 'Feed RSS') }

    before :each do
      allow(Feedjira::Feed).to receive(:fetch_and_parse).with(url).and_return(rss_feed)
      allow(OAuth2::Client).to receive(:new).with(client_id, secret, site: "#{indexador_scheme}://#{indexador_host}:#{indexador_port}", token_method: :post)
                           .and_return(oauth_client)
      allow(oauth_client).to receive(:client_credentials).and_return(double(get_token: access_token))
    end

    around :each do |example|
      previous_indexador_scheme = ENV['INDEXADOR_SCHEME']
      previous_indexador_host = ENV['INDEXADOR_HOST']
      previous_indexador_port = ENV['INDEXADOR_PORT']
      previous_indexador_client_id = ENV['INDEXADOR_CLIENT_ID']
      previous_indexador_secret = ENV['INDEXADOR_SECRET']

      ENV['INDEXADOR_SCHEME'] = indexador_scheme
      ENV['INDEXADOR_HOST'] = indexador_host
      ENV['INDEXADOR_PORT'] = indexador_port
      ENV['INDEXADOR_CLIENT_ID'] = client_id
      ENV['INDEXADOR_SECRET'] = secret

      example.run

      ENV['INDEXADOR_HOST'] = previous_indexador_host
      ENV['INDEXADOR_PORT'] = previous_indexador_port
      ENV['INDEXADOR_SCHEME'] = previous_indexador_scheme
      ENV['INDEXADOR_CLIENT_ID'] = previous_indexador_client_id
      ENV['INDEXADOR_SECRET'] = previous_indexador_secret
    end

    context 'last_fetch_at is nil' do
      before :each do
        rss_entries.each do |entry|
          expect(access_token).to receive(:post)
                              .with('/api/v1/contents.json',
                                    headers: {'Content-Type' => 'application/json'},
                                    body: {title: entry.title, body: entry.content, url: entry.url, creator: entry.author, published_at: entry.published, source: 'rss'}.to_json,
                                    raise_errors: false
                              )
                              .and_return(double(status: 201))
        end
      end

      it 'should call new content endpoint on Indexador for each entry' do
        subject.fetch_and_publish_new!
      end

      it 'should update last_fetch_at' do
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
        expect(access_token).to receive(:post)
                              .with('/api/v1/contents.json',
                                    headers: {'Content-Type' => 'application/json'},
                                    body: {title: rss_entries.last.title, body: rss_entries.last.content, url: rss_entries.last.url, creator: rss_entries.last.author, published_at: rss_entries.last.published, source: 'rss'}.to_json,
                                    raise_errors: false
                              )
                              .and_return(double(status: 201))

        subject.fetch_and_publish_new!
      end
    end
  end
end
