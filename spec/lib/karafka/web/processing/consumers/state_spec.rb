# frozen_string_literal: true

RSpec.describe_current do
  let(:states_topic) { Karafka::Web.config.topics.consumers.states = create_topic }
  let(:fixture) { Fixtures.consumers_states_file }

  describe '#current!' do
    subject(:state) { described_class.current! }

    before { states_topic }

    context 'when there is no current state' do
      let(:expected_error) { ::Karafka::Web::Errors::Processing::MissingConsumersStateError }

      it { expect { state }.to raise_error(expected_error) }
    end

    context 'when states topic does not exist' do
      let(:expected_error) do
        ::Karafka::Web::Errors::Processing::MissingConsumersStatesTopicError
      end

      before { Karafka::Web.config.topics.consumers.states = SecureRandom.uuid }

      it { expect { state }.to raise_error(expected_error) }
    end

    context 'when current state exists' do
      before { produce(states_topic, fixture) }

      it 'expect to get it with the data inside' do
        expect(state).to be_a(Hash)
        expect(state.key?(:processes)).to be(true)
        expect(state.key?(:stats)).to be(true)
        expect(state.key?(:schema_version)).to be(true)
        expect(state.key?(:dispatched_at)).to be(true)
      end
    end
  end
end
