# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:current_state) { { dispatched_at: Time.now.to_f } }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:initial_consumers_metrics) }
    it { expect(described_class.halted_details).to be_nil }
  end

  describe '#call' do
    before do
      context.current_state = current_state
    end

    context 'when processes can be loaded successfully' do
      let(:processes) { [double('Process')] }

      before do
        allow(Karafka::Web::Ui::Models::Processes)
          .to receive(:all)
          .with(current_state)
          .and_return(processes)
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details).to be_nil
      end

      it 'caches processes in context' do
        check.call

        expect(context.processes).to eq(processes)
      end
    end

    context 'when processes data is corrupted (JSON parse error)' do
      before do
        allow(Karafka::Web::Ui::Models::Processes)
          .to receive(:all)
          .and_raise(JSON::ParserError)
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.details).to be_nil
      end
    end

    context 'when processes are already cached in context' do
      let(:processes) { [double('Process')] }

      before do
        context.processes = processes
      end

      it 'does not fetch again' do
        expect(Karafka::Web::Ui::Models::Processes).not_to receive(:all)

        result = check.call

        expect(result.status).to eq(:success)
      end
    end
  end
end
