# frozen_string_literal: true

RSpec.describe_current do
  subject(:ttl_hash) { described_class.new(100) }

  context 'when we add data into the hash' do
    before { ttl_hash[:test] << 1 }

    it { expect(ttl_hash[:test].to_a).to eq([1]) }

    context 'when enough time has passed' do
      before { sleep(0.1) }

      it { expect(ttl_hash[:test].to_a).to eq([]) }
    end
  end

  context 'when running inspect while extending hash data' do
    let(:ttl_hash) { described_class.new(5000) }

    it 'safely handles inspect during concurrent modifications' do
      errors = []

      writer = Thread.new do
        20.times { |i| ttl_hash["key_#{i}"] << [i, Time.now.to_f * 1000] }
      rescue StandardError => e
        errors << e
      end

      inspector = Thread.new do
        10.times { expect(ttl_hash.inspect).to include('Ttls::Hash') }
      rescue StandardError => e
        errors << e
      end

      [writer, inspector].each(&:join)
      expect(errors).to be_empty
    end
  end
end
