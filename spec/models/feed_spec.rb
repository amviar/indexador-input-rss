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

  describe '#fetch_and_publish_new' do
    let(:url) { 'http://www.example.com/rss' }
    let(:rss_feed) { double(entries: rss_entries) }
    let(:rss_entries) do
      [ double(last_modified: DateTime.now - 1.day, title: '', content: '', url: '', author: '', published: ''),
        double()
      ]
    end

    subject { Feed.new(url: url) }

    before :each do
      allow(Feedjira::Feed).to receive(:fetch_and_parse).with(url).and_return(rss_feed)
    end

    it 'should call new content endpoint on Indexador for each entry' do

    end
  end
end
