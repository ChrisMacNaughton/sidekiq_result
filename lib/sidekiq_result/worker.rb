module Sidekiq::Result::Worker
  attr_accessor :expiration

  def store_result?
    true
  end
end