# Worker is the module included in a worker so that we know
# the user wants to track the jobs' results
#
# @!attribute expiration
#   @return [Integer] How long to leave item in Redis (TTL)

module Sidekiq::Result::Worker
  attr_accessor :expiration

  # Internal method used to ensure user wants to track the result
  # The user MUST include this module in their Worker as per the readme
  # if they want to track the job results
  def store_result?
    true
  end
end