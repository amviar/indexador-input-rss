require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV['RACK_ENV'] || :development)

Dotenv.load ".env.#{ENV['RACK_ENV']}", '.env'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../app'))

Mongoid.load!("mongoid.yml")

require 'models/feed'
