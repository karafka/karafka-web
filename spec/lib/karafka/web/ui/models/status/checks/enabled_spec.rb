# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(true) }
    it { expect(described_class.dependency).to be_nil }
  end

  describe '#call' do
    context 'when web ui group is in routes' do
      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
        expect(result.details).to eq({})
      end
    end

    context 'when web ui group is not in routes' do
      before do
        allow(Karafka::Web.config).to receive(:group_id).and_return('non_existent_group')
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.success?).to be(false)
        expect(result.details).to eq({})
      end
    end
  end
end
