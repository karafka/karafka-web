# frozen_string_literal: true

describe_current do
  let(:create) { described_class.new.call(1) }

  let(:topics) { Karafka::Web::Ui::Models::ClusterInfo.topics.map(&:topic_name) }

  context "when consumers states topic exists" do
    let(:consumers_states_topic) { create_topic }

    before do
      Karafka::Web.config.topics.consumers.states.name = consumers_states_topic
      # Produce one message to check if the topic is not re-created
      produce(consumers_states_topic, {}.to_json)
    end

    it "expect not to create it again" do
      create
      Karafka::Web::Processing::Consumers::State.current!
    end
  end

  context "when consumers states topic does not exist" do
    let(:consumers_states_topic) { generate_topic_name }

    before { Karafka::Web.config.topics.consumers.states.name = consumers_states_topic }

    it "expect to create it" do
      create

      assert_includes(topics, consumers_states_topic)
    end
  end

  context "when consumers metrics topic exists" do
    let(:consumers_metrics_topic) { create_topic }

    before do
      Karafka::Web.config.topics.consumers.metrics.name = consumers_metrics_topic
      produce(consumers_metrics_topic, {}.to_json)
    end

    it "expect not to create it again" do
      create
      Karafka::Web::Processing::Consumers::Metrics.current!
    end
  end

  context "when consumers metrics topic does not exist" do
    let(:consumers_metrics_topic) { generate_topic_name }

    before { Karafka::Web.config.topics.consumers.metrics.name = consumers_metrics_topic }

    it "expect to create it" do
      create

      assert_includes(topics, consumers_metrics_topic)
    end
  end

  context "when consumers reports topic exists" do
    let(:consumers_reports_topic) { create_topic }

    before do
      Karafka::Web.config.topics.consumers.reports.name = consumers_reports_topic
      produce(consumers_reports_topic, {}.to_json)
    end

    it "expect not to create it again" do
      create

      assert_equal(1, Karafka::Admin.read_topic(consumers_reports_topic, 0, 100).size)
    end
  end

  context "when consumers reports topic does not exist" do
    let(:consumers_reports_topic) { generate_topic_name }

    before { Karafka::Web.config.topics.consumers.reports.name = consumers_reports_topic }

    it "expect to create it" do
      create

      assert_includes(topics, consumers_reports_topic)
    end
  end

  context "when errors topic exists" do
    let(:errors_topic) { create_topic }

    before do
      Karafka::Web.config.topics.errors.name = errors_topic
      produce(errors_topic, {}.to_json)
    end

    it "expect not to create it again" do
      create

      assert_equal(1, Karafka::Admin.read_topic(errors_topic, 0, 100).size)
    end
  end

  context "when errors topic does not exist" do
    let(:errors_topic) { generate_topic_name }

    before { Karafka::Web.config.topics.errors.name = errors_topic }

    it "expect to create it" do
      create

      assert_includes(topics, errors_topic)
    end
  end

  describe "#min_insync_replicas" do
    let(:action) { described_class.new }

    it "expect to return an integer no greater than the given replication factor" do
      result = action.send(:min_insync_replicas, 1)

      assert_kind_of(Integer, result)
      assert_operator(result, :<=, 1)
    end

    it "expect to never exceed a higher requested replication factor either" do
      result = action.send(:min_insync_replicas, 3)

      assert_kind_of(Integer, result)
      assert_operator(result, :<=, 3)
    end
  end

  context "when a topic is created" do
    let(:consumers_states_topic) { generate_topic_name }
    let(:expected_min_isr) { described_class.new.send(:min_insync_replicas, 1) }

    let(:persisted_min_isr) do
      resource = Karafka::Admin::Configs::Resource.new(type: :topic, name: consumers_states_topic)

      Karafka::Admin::Configs
        .describe(resource)
        .first
        .configs
        .find { |config| config.name == "min.insync.replicas" }
        .value
        .to_i
    end

    before { Karafka::Web.config.topics.consumers.states.name = consumers_states_topic }

    it "expect the persisted min.insync.replicas to match the computed value" do
      create

      assert_equal(expected_min_isr, persisted_min_isr)
    end
  end
end
