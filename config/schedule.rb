set :environment, ENV['RACK_ENV']
set :output, 'log/cron_log.log'

every 1.hour do
  rake 'indexador_input_rss:fetch_and_publish'
end
