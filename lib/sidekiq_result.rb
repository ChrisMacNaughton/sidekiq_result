require 'sidekiq_result/version'
require 'sidekiq_result/storage'
require 'sidekiq_result/server_middleware'
require 'sidekiq_result/worker'


# An extension to Sidekiq message processing to track your job results.
module Sidekiq::Result
  extend Storage
  DEFAULT_EXPIRATION = 5 * 60 # 5 minute timeouts

  class << self
    # Check if job has registered complete by storing key
    # in it's space
    def complete? id
      !check_for_key(id).empty?
    end

    # The result from the Sidekiq worker
    def result(id)
      get_object_for_id(id)
    end

    private
  end
end
