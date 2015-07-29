require 'base64'
# Storage is used to wrap all Redis persistence
module Sidekiq::Result::Storage
  protected

  # Gets the object stored at the given key
  # @param [String] id Sidekiq worker's JID
  # @param [RedisPool] redis_pool the pool to use for connections to Redis
  def get_object_for_id(id, redis_pool = nil)
    redis_connection(redis_pool) do |conn|
      decode_object_from_redis(conn.get(key(id)))
    end
  end

  # Checks if a given key is present
  # Returns an array of matching keys
  # @param [String] id Sidekiq worker's JID
  # @param [RedisPool] redis_pool the pool to use for connections to Redis
  def check_for_key(id, redis_pool = nil)
    redis_connection(redis_pool) do |conn|
      keys = conn.keys(key(id))
    end
  end

  # Stores the given object in the specific key
  # Returns true / false based on success of storage
  # @param [String] id Sidekiq worker's JID, used to track jobs internally
  # @param [Object] object The object that we are going to marshal and store in Redis
  # @param [Integer] expiration the number of seconds to store the result in Redis
  # @param [RedisPool] redis_pool the pool to use for connections to Redis
  def set_object_for_id(id, object, expiration = nil, redis_pool = nil)
    object = encode_object_for_redis(object)
    return false if object.nil?
    redis_connection(redis_pool) do |conn|
      conn.setex(key(id), expiration || Sidekiq::Result::DEFAULT_EXPIRATION, object)
    end
    true
  end

  private

  def encode_object_for_redis(object)
    begin
      Base64.encode64(Marshal.dump(object))
    rescue
      nil
    end
  end

  def decode_object_from_redis(string)
    begin
      Marshal.load(Base64.decode64(string))
    rescue
      nil
    end
  end

  def redis_connection(redis_pool=nil)
    if redis_pool
      redis_pool.with do |conn|
        yield conn
      end
    else
      Sidekiq.redis do |conn|
        yield conn
      end
    end
  end

  def key(id)
    "sidekiq:result:#{id}"
  end
end