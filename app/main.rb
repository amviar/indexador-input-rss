require_relative 'helpers/javascript_helper'

class Main < Sinatra::Base
  include JavascriptHelper

  enable :sessions
  use Rack::Flash
  set :logging, true

  get '/' do
    @feeds = Feed.all
    erb :index
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
