class StubJob
  include Sidekiq::Worker
  include Sidekiq::Result::Worker
  sidekiq_options 'retry' => 'false'

  def perform(*args)
    true
  end
end

class LongJob < StubJob
  def perform(*args)
    sleep args[0] || 1
  end
end

class TestJob < StubJob
  def perform(*args)
    args[0] || 'Complete!'
  end
end

class NilJob < StubJob
  def perform(*args)
    nil
  end
end

class ObjectJob < StubJob
  def perform(*args)
    TestClass.new
  end
end

class TestClass
  attr_reader :name
  def initialize(name = 'World')
    @name = name
  end
end