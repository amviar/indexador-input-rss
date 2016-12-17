require 'net/http'

class Feed
  include Mongoid::Document

  field :name, type: String
  field :url, type: String
  field :slug, type: String
  field :last_fetch_at, type: DateTime

  before_validation :calculate_slug, if: -> { self.slug.blank? }

  validates :slug, uniqueness: true
  validates :url, uniqueness: true

  def fetch_and_publish_new
    rss_feed = Feedjira::Feed.fetch_and_parse url

    rss_feed.entries.each do |entry|
      next if !last_fetch_at.nil? && entry.last_modified < last_fetch_at

      req = Net::HTTP.post_form({title: entry.title, body: entry.content, url: entry.url, creator: entry.author, published_at: entry.published, source: 'rss'}.to_json)
    end

    last_fetch_at = Date.now
    save!
  end

  private

  def calculate_slug
    name_slug = name.downcase.gsub(/\s/, '-')
    self.slug = name_slug

    i = 1
    while Feed.where(slug: name_slug).any?
      self.slug = "#{name_slug}-#{i}"
      i += 1
    end
  end
end
