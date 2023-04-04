# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:config) do
    {
      id: 0,
      lag_stored: 0,
      lag_stored_d: 0,
      committed_offset: 0,
      stored_offset: 0
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(config)).to be_success }
  end

  context 'when id is less than 0' do
    before { config[:id] = -1 }

    it { expect(contract.call(config)).not_to be_success }
  end

  %i[
    id
    lag_stored
    lag_stored_d
    committed_offset
    stored_offset
  ].each do |key|
    context "when #{key} is not numeric" do
      before { config[key] = '2' }

      it { expect(contract.call(config)).not_to be_success }
    end

    context "when #{key} is missing" do
      before { config.delete(key) }

      it { expect(contract.call(config)).not_to be_success }
    end
  end
end
