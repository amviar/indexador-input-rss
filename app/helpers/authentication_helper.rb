module AuthenticationHelper
  class << self
    def included(base)
      base.helpers do
        def authenticated?
          !session[:access_token].nil?
        end

        def authenticating?
          request.path == '/signing_in' || request.path == '/callback' || request.path == '/sign_out'
        end

        def sign_in

        end

        def sign_out
          session[:access_token] = nil
          redirect '/'
        end

        def current_user
          @user ||= OpenStruct.new(email: session[:email])
        end

        def oauth2_client
          uri_indexador = "#{request.scheme}://#{ENV['INDEXADOR_HOST']}"
          if !ENV['INDEXADOR_PORT'].nil? && ENV['INDEXADOR_PORT'] != ''
            uri_indexador += ":#{ENV['INDEXADOR_PORT']}"
          end

          OAuth2::Client.new(
            ENV['INDEXADOR_CLIENT_ID'],
            ENV['INDEXADOR_SECRET'],
            site: uri_indexador,
            token_method: :post
          )
        end

        def callback_uri
          hostname = request.host

          uri = "#{request.scheme}://#{request.host}"

          port = request.port
          if port != 80 && port != 443
            uri += ":#{port}"
          end

          uri += "/callback"

          uri
        end
      end
    end
  end
end
