require 'spec_helper'

describe Sidekiq::Result do
  let!(:redis) { Sidekiq.redis { |conn| conn } }
  let!(:job_id) { SecureRandom.hex(12) }
  # Clean Redis before each test
  # Seems like flushall has no effect on recently published messages,
  # so we should wait till they expire
  before { redis.flushall; sleep 0.1 }

  describe '.complete?' do
    it 'knows if a job is complete' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)
      start_server do
        id = LongJob.perform_async
        expect(id).to eq(job_id)
        expect(Sidekiq::Result.complete?(job_id)).to be_falsey
      end
      expect(Sidekiq::Result.complete?(job_id)).to be_truthy
    end
  end

  describe '.result' do
    it 'can get the result from a complete job' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)
      start_server do
        id = TestJob.perform_async
        expect(id).to eq(job_id)
        expect(Sidekiq::Result.complete?(job_id)).to be_falsey
      end
      expect(Sidekiq::Result.complete?(job_id)).to be_truthy
      expect(Sidekiq::Result.result(job_id)).to eq('Complete!')
    end

    it 'can handle objects as the response' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)
      start_server do
        id = ObjectJob.perform_async
        expect(id).to eq(job_id)
        expect(Sidekiq::Result.complete?(job_id)).to be_falsey
      end
      expect(Sidekiq::Result.complete?(job_id)).to be_truthy
      expect(Sidekiq::Result.result(job_id).name).to eq('World')
    end

    it 'can handle nil as the result' do
      allow(SecureRandom).to receive(:hex).once.and_return(job_id)

      start_server do
        expect(NilJob.perform_async).to eq(job_id)
      end
      expect(Sidekiq::Result.result(job_id)).to eq(nil)
    end
  end
end
