require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV['RACK_ENV'] || :development)

Dotenv.load ".env.#{ENV['RACK_ENV']}", '.env'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app'))
require 'main'

Mongoid.load!("mongoid.yml")

map '/css' do
  run Rack::Directory.new "./public/stylesheets"
end

map '/js' do
  run Rack::Directory.new "./public/javascripts"
end

map '/' do
  run Main
end
