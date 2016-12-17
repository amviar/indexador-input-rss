#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,

# require File.expand_path('../config/application', __FILE__)

# Agra::Application.load_tasks

# task :default => ['spec', 'scenarios']
# Knapsack.load_tasks if defined?(Knapsack)

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  ENV['RACK_ENV'] = 'test'

  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rspec_opts = '--color'
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
