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

  def fetch_and_publish_new!
    rss_feed = Feedjira::Feed.fetch_and_parse url

    rss_feed.entries.each do |entry|
      next if !last_fetch_at.nil? && entry.last_modified < last_fetch_at

      res = access_token.post('/api/v1/contents.json',
                        headers: {'Content-Type' => 'application/json'},
                        body: { title: entry.title, body: entry.content, url: entry.url, creator: entry.author, published_at: entry.published, source: 'rss' }.to_json,
                        raise_errors: false
      )

      case res.status
      when 200..299
        logger.info "Contenido '#{entry.title}' de '#{self.name}' insertado exitosamente en el Indexador"
      else
        raise "Error al intentar insertar contenido '#{entry.title}' de '#{self.name}' al indexador. HTTP Response: #{res.inspect}."
      end
    end

    self.last_fetch_at = DateTime.now
    save!
  end

  private

  def calculate_slug
    name_slug = name.downcase.gsub(/\s/, '-').gsub(/[^a-zA-Z0-9]/, '-')
    self.slug = name_slug

    i = 1
    while Feed.where(slug: name_slug).any?
      self.slug = "#{name_slug}-#{i}"
      i += 1
    end
  end

  def indexador_hostname
    raise 'Configuración inválida, falta definir INDEXADOR_HOST' unless ENV['INDEXADOR_HOST'].present?
    ENV['INDEXADOR_HOST']
  end

  def indexador_port
    ENV['INDEXADOR_PORT'] || 443
  end

  def access_token
    @_access_token ||= oauth2_client.client_credentials.get_token
  end

  def oauth2_client
    return @_oauth2_client unless @_oauth2_client.nil?

    uri_indexador = "#{ENV['INDEXADOR_SCHEME']}://#{ENV['INDEXADOR_HOST']}"
    if !ENV['INDEXADOR_PORT'].nil? && ENV['INDEXADOR_PORT'] != ''
      uri_indexador += ":#{ENV['INDEXADOR_PORT']}"
    end

    @_oauth2_client = OAuth2::Client.new(
      ENV['INDEXADOR_CLIENT_ID'],
      ENV['INDEXADOR_SECRET'],
      site: uri_indexador,
      token_method: :post
    )
  end
end
