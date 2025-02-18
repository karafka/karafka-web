# frozen_string_literal: true

RSpec.describe_current do
  subject(:stats) { described_class.new(ttls_hash) }

  let(:ttls_hash) do
    {
      'group1' => ttls_array1,
      'group2' => ttls_array2
    }
  end

  let(:ttls_array1) { Karafka::Web::Tracking::Helpers::Ttls::Array.new(1_000) }
  let(:ttls_array2) { Karafka::Web::Tracking::Helpers::Ttls::Array.new(1_000) }

  describe '#rps' do
    context 'when all arrays are empty' do
      before do
        allow(ttls_array1).to receive(:samples).and_return([])
        allow(ttls_array2).to receive(:samples).and_return([])
      end

      it { expect(stats.rps).to eq(0) }
    end

    context 'when arrays have only one sample' do
      before do
        allow(ttls_array1)
          .to receive(:samples)
          .and_return([{ value: 10, added_at: 1000 }])

        allow(ttls_array2)
          .to receive(:samples)
          .and_return([])
      end

      it { expect(stats.rps).to eq(0) }
    end

    context 'when arrays have enough samples' do
      before do
        allow(ttls_array1)
          .to receive(:samples)
          .and_return([{ value: 100, added_at: 2000 }, { value: 80, added_at: 1000 }])

        allow(ttls_array2)
          .to receive(:samples)
          .and_return([{ value: 50, added_at: 2000 }, { value: 20, added_at: 1000 }])
      end

      it 'computes rps as an aggregate from all the samples' do
        # For group1: (100 - 80) / (2000 - 1000) * 1000 = 20 rps
        # For group2: (50 - 20) / (2000 - 1000) * 1000 = 30 rps
        # Total: 50 rps
        expect(stats.rps).to eq(50)
      end
    end

    context 'when some arrays have insufficient samples' do
      before do
        allow(ttls_array1)
          .to receive(:samples)
          .and_return([{ value: 100, added_at: 2000 }, { value: 80, added_at: 1000 }])

        allow(ttls_array2)
          .to receive(:samples)
          .and_return([{ value: 50, added_at: 2000 }])
      end

      it 'computes rps only from arrays with enough samples' do
        # Only group1 has enough samples
        # (100 - 80) / (2000 - 1000) * 1000 = 20 rps
        expect(stats.rps).to eq(20)
      end
    end
  end
end
