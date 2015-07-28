require 'sidekiq_result/version'
require 'sidekiq_result/storage'
require 'sidekiq_result/server_middleware'
require 'sidekiq_result/worker'
module Sidekiq::Result
  extend Storage
  DEFAULT_EXPIRATION = 5 * 60 # 5 minute timeouts

  class << self
    # Check if job has registered complete by storing key
    # in it's space
    def complete? id
      !get_object_for_id(id).nil?
    end

    def result(id)
      get_object_for_id(id)
    end

    private
  end
end
