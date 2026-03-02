# frozen_string_literal: true

describe_current do
  let(:states_topic) { Karafka::Web.config.topics.consumers.states.name = create_topic }
  let(:fixture) { Fixtures.consumers_states_file }

  describe "#current!" do
    let(:state) { described_class.current! }

    before { states_topic }

    context "when there is no current state" do
      let(:expected_error) { Karafka::Web::Errors::Processing::MissingConsumersStateError }

      it { assert_raises(expected_error) { state } }
    end

    context "when states topic does not exist" do
      let(:expected_error) do
        Karafka::Web::Errors::Processing::MissingConsumersStatesTopicError
      end

      before { Karafka::Web.config.topics.consumers.states.name = generate_topic_name }

      it { assert_raises(expected_error) { state } }
    end

    context "when current state exists" do
      before { produce(states_topic, fixture) }

      it "expect to get it with the data inside" do
        assert_kind_of(Hash, state)
        assert(state.key?(:processes))
        assert(state.key?(:stats))
        assert(state.key?(:schema_version))
        assert(state.key?(:dispatched_at))
      end
    end
  end
end
