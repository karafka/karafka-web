# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:consumers_reports) }
    it { expect(described_class.halted_details).to be_nil }
  end

  describe '#call' do
    context 'when there are active processes' do
      before do
        context.processes = [double('Process'), double('Process')]
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
      end
    end

    context 'when there are no processes' do
      before do
        context.processes = []
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.success?).to be(false)
      end
    end
  end
end
