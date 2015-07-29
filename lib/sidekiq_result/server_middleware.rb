module Sidekiq::Result
  # ServerMiddleware must be included in the server Middlware Chain
  # for the tracking functionality to work. It is used to wrap the
  # actual job performance.
  class ServerMiddleware
    include Storage

    # Parameterized initialization, use it when adding middleware to server chain
    # chain.add Sidekiq::Result::ServerMiddleware, :expiration => 60 * 5
    # @param [Hash] opts middleware initialization options
    # @option opts [Fixnum] :expiration ttl for saving complete jobs
    def initialize(opts = {})
      @expiration = opts[:expiration]
    end

    # Uses sidekiq's internal jid as id
    # saves result of worker's method into the specified key
    # @param [Worker] worker worker instance, processed here if it's class includesResult::Worker
    # @param [Array] msg job args, should have jid format
    # @param [String] queue queue name
    def call(worker, msg, queue)
      # a way of overriding default expiration time,
      # so worker wouldn't lose its data
      # and it allows also to overwrite global expiration time on worker basis
      if worker.respond_to? :expiration
        if !worker.expiration && worker.respond_to?(:expiration=)
          worker.expiration = @expiration
        else
          @expiration = worker.expiration
        end
      end
      result = yield
      if worker.respond_to?(:store_result?) && worker.store_result?
        set_object_for_id(worker.jid, result, @expiration)
      end
    end
  end
end