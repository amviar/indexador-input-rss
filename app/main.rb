class Main < Sinatra::Base
  enable :sessions
  use Rack::Flash

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

    @feeds = Feed.all
    erb :index
  end

  delete '/feeds' do
    feed = Feed.find_by(slug: params[:slug])
    if feed.destroy
      flash[:notice] = 'Feed borrado'
    else
      flash[:alert] = "Error al borrar el feed: #{feed.errors}"
    end

    @feeds = Feed.all
    erb :index
  end
end
