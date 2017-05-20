#!/usr/bin/env rake
if ENV['RACK_ENV'] == 'test'
  require 'rspec/core/rake_task'

  desc 'Default: run specs.'
  task :default => :spec

  desc "Run specs"
  RSpec::Core::RakeTask.new do |t|
    t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
    t.rspec_opts = '--color'
  end
end

require_relative 'config/environment'

namespace :indexador_input_rss do
  desc 'Descargar nuevos contenidos de todos los feeds RSS y publicarlos en el Indexador'
  task :fetch_and_publish do
    Feed.all.each do |feed|
      feed.fetch_and_publish_new!
    end
  end
end
