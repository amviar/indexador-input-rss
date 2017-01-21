require_relative 'helpers/javascript_helper'
require_relative 'helpers/authentication_helper'

class Main < Sinatra::Base
  include JavascriptHelper
  include AuthenticationHelper

  enable :sessions
  use Rack::Flash
  set :logging, true

  before do
    redirect '/signing_in' unless (authenticated? || authenticating?)
  end

  get '/' do
    @feeds = Feed.all
    erb :index
  end

  get '/signing_in' do
    redirect oauth2_client.auth_code.authorize_url(redirect_uri: callback_uri, scope: 'public')
  end

  get '/callback' do
    new_token = oauth2_client.auth_code.get_token(params[:code], redirect_uri: callback_uri)
    session[:access_token]  = new_token.token
    session[:refresh_token] = new_token.refresh_token
    redirect '/'
  end

  get '/sign_out' do
    sign_out
    redirect '/'
  end

  post '/feeds' do
    feed = Feed.new(params[:feed])

    if feed.save
      flash[:notice] = 'Feed guardado'
    else
      flash[:alert] = "Error al guardar el feed: #{feed.errors}"
    end

    redirect '/'
  end

  delete '/feeds' do
    feed = Feed.find_by(slug: params[:slug])
    if feed.destroy
      flash[:notice] = 'Feed borrado'
    else
      flash[:alert] = "Error al borrar el feed: #{feed.errors}"
    end

    @feeds = Feed.all

    erb :delete_success, content_type: 'application/javascript'
  end
end
