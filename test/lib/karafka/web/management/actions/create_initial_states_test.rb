# frozen_string_literal: true

describe_current do
  let(:create) { described_class.new.call }

  let(:consumers_states_topic) { create_topic }
  let(:consumers_metrics_topic) { create_topic }
  let(:consumers_state) { Karafka::Web::Processing::Consumers::State.current! }
  let(:consumers_metrics) { Karafka::Web::Processing::Consumers::Metrics.current! }

  before do
    Karafka::Web.config.topics.consumers.states.name = consumers_states_topic
    Karafka::Web.config.topics.consumers.metrics.name = consumers_metrics_topic
  end

  context "when the consumers state already exists" do
    before { produce(consumers_states_topic, Fixtures.consumers_states_file) }

    it "expect not to overwrite it" do
      create
      assert_equal(2_690_818_670.782_473, consumers_state[:dispatched_at])
    end
  end

  context "when the consumers state is missing" do
    let(:initial_state) { { schema_version: "0.0.0" } }

    it "expect to create it with appropriate values" do
      create
      assert_equal(initial_state, consumers_state)
    end
  end

  context "when the consumers metrics already exists" do
    before { produce(consumers_metrics_topic, Fixtures.consumers_metrics_file) }

    it "expect not to overwrite it" do
      create
      assert_equal(1_690_817_198.082_236, consumers_metrics[:dispatched_at])
    end
  end

  context "when the consumers metrics is missing" do
    let(:initial_state) { { schema_version: "0.0.0" } }

    it "expect to create it with appropriate values" do
      create
      assert_equal(initial_state, consumers_metrics)
    end
  end
end
