# frozen_string_literal: true

describe_current do
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:fixture) { Fixtures.consumers_metrics_file }

  describe "#current!" do
    let(:metrics) { described_class.current! }

    before { metrics_topic }

    context "when there is no current state" do
      let(:expected_error) { Karafka::Web::Errors::Processing::MissingConsumersMetricsError }

      it { assert_raises(expected_error) { metrics } }
    end

    context "when metrics topic does not exist" do
      let(:expected_error) do
        Karafka::Web::Errors::Processing::MissingConsumersMetricsTopicError
      end

      before { Karafka::Web.config.topics.consumers.metrics.name = generate_topic_name }

      it { assert_raises(expected_error) { metrics } }
    end

    context "when current state exists" do
      before { produce(metrics_topic, fixture) }

      it "expect to get it with the data inside" do
        assert_kind_of(Hash, metrics)
        assert(metrics.key?(:aggregated))
        assert(metrics.key?(:consumer_groups))
        assert(metrics.key?(:schema_version))
        assert(metrics.key?(:dispatched_at))
      end
    end
  end
end
