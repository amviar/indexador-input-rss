require_relative 'config/environment'
require 'main'

map '/css' do
  run Rack::Directory.new "./public/stylesheets"
end

map '/js' do
  run Rack::Directory.new "./public/javascripts"
end

map '/' do
  run Main
end
