# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:replication) }
    it { expect(described_class.halted_details).to eq({ issue_type: :presence }) }
  end

  describe '#call' do
    context 'when consumers state is present and valid' do
      let(:state) { { dispatched_at: Time.now.to_f, schema_state: 'compatible' } }

      before do
        allow(Karafka::Web::Ui::Models::ConsumersState).to receive(:current).and_return(state)
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details[:issue_type]).to eq(:presence)
      end

      it 'caches the state in context' do
        check.call

        expect(context.current_state).to eq(state)
      end
    end

    context 'when consumers state is not present' do
      before do
        allow(Karafka::Web::Ui::Models::ConsumersState).to receive(:current).and_return(nil)
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.details[:issue_type]).to eq(:presence)
      end
    end

    context 'when consumers state is corrupted (JSON parse error)' do
      before do
        allow(Karafka::Web::Ui::Models::ConsumersState)
          .to receive(:current)
          .and_raise(JSON::ParserError)
      end

      it 'returns failure with deserialization issue type' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.details[:issue_type]).to eq(:deserialization)
      end
    end

    context 'when state is already cached in context' do
      let(:state) { { dispatched_at: Time.now.to_f } }

      before do
        context.current_state = state
        allow(Karafka::Web::Ui::Models::ConsumersState).to receive(:current)
      end

      it 'does not fetch again' do
        check.call

        expect(Karafka::Web::Ui::Models::ConsumersState).not_to have_received(:current)
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
      end
    end
  end
end
