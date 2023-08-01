# frozen_string_literal: true

RSpec.describe_current do
  subject(:partition) { described_class.new(data) }

  let(:data) { {} }

  describe '#lag' do
    context 'when not available' do
      it { expect(partition.lag).to eq(-1) }
    end

    context 'when available' do
      let(:data) { { lag: 100 } }

      it { expect(partition.lag).to eq(100) }
    end
  end
end
