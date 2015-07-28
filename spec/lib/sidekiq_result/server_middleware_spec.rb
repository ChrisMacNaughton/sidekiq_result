require 'spec_helper'
require 'ostruct'
describe Sidekiq::Result::ServerMiddleware do
  include Sidekiq::Result::Storage
  let!(:redis) { Sidekiq.redis { |conn| conn } }
  let!(:job_id) { SecureRandom.hex(12) }

  # Clean Redis before each test
  # Seems like flushall has no effect on recently published messages,
  # so we should wait till they expire
  before { redis.flushall; sleep 0.1 }

  describe '#call' do
    it 'saves the result' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)
       start_server do
        expect(TestJob.perform_async('Saved!')).to eq(job_id)
      end
      expect(get_object_for_id(job_id)).to eq("Saved!")
    end

    it 'sets an expiration' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)
      start_server do
        expect(StubJob.perform_async(:arg1 => 'val1')).to eq(job_id)
      end
      expect(1..Sidekiq::Result::DEFAULT_EXPIRATION).to cover redis.ttl("sidekiq:result:#{job_id}")
    end
  end
end