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
end
