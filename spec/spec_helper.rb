require "rspec"
require 'pry'
require 'celluloid'
require 'sidekiq'
require 'sidekiq/processor'
require 'sidekiq/manager'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sidekiq_result'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Sidekiq.configure_client do |config|
#   config.client_middleware do |chain|
#     chain.add Sidekiq::Result::ClientMiddleware
#   end
# end

def confirmations_thread(messages_limit, *channels)
  parent = Thread.current
  thread = Thread.new {
    confirmations = []
    Sidekiq.redis do |conn|
      conn.subscribe *channels do |on|
        on.subscribe do |ch, subscriptions|
          if subscriptions == channels.size
            sleep 0.1 while parent.status != "sleep"
            parent.run
          end
        end
        on.message do |ch, msg|
          confirmations << msg
          conn.unsubscribe if confirmations.length >= messages_limit
        end
      end
    end
    confirmations
  }
  Thread.stop
  yield if block_given?
  thread
end

def start_server(server_middleware_options={})
  pid = Process.fork do
    $stdout.reopen File::NULL, 'w'
    $stderr.reopen File::NULL, 'w'
    require 'sidekiq/cli'
    Sidekiq.options[:queues] << 'default'
    Sidekiq.options[:require] =  File.expand_path('../support/test_jobs.rb', __FILE__)
    Sidekiq.configure_server do |config|
      config.redis = Sidekiq::RedisConnection.create
      config.server_middleware do |chain|
        chain.add Sidekiq::Result::ServerMiddleware, server_middleware_options
      end
    end
    Sidekiq::CLI.instance.run
  end
  res = yield
  sleep 0.1
  Process.kill 'TERM', pid
  Timeout::timeout(10) { Process.wait pid } rescue Timeout::Error
ensure
  Process.kill 'KILL', pid rescue "OK" # it's OK if the process is gone already
end