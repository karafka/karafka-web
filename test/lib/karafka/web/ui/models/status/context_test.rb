# frozen_string_literal: true

describe_current do
  let(:context) { described_class.new }

  describe "accessors" do
    it { assert_respond_to(context, :cluster_info) }
    it { assert_respond_to(context, :cluster_info=) }
    it { assert_respond_to(context, :connection_time) }
    it { assert_respond_to(context, :connection_time=) }
    it { assert_respond_to(context, :current_state) }
    it { assert_respond_to(context, :current_state=) }
    it { assert_respond_to(context, :current_metrics) }
    it { assert_respond_to(context, :current_metrics=) }
    it { assert_respond_to(context, :processes) }
    it { assert_respond_to(context, :processes=) }
    it { assert_respond_to(context, :subscriptions) }
    it { assert_respond_to(context, :subscriptions=) }
  end

  describe "#topics_consumers_states" do
    it "returns the configured states topic name" do
      assert_equal( Karafka::Web.config.topics.consumers.states.name.to_s , context.topics_consumers_states)
    end
  end

  describe "#topics_consumers_reports" do
    it "returns the configured reports topic name" do
      assert_equal( Karafka::Web.config.topics.consumers.reports.name.to_s , context.topics_consumers_reports)
    end
  end

  describe "#topics_consumers_metrics" do
    it "returns the configured metrics topic name" do
      assert_equal( Karafka::Web.config.topics.consumers.metrics.name.to_s , context.topics_consumers_metrics)
    end
  end

  describe "#topics_errors" do
    it "returns the configured errors topic name" do
      assert_equal(Karafka::Web.config.topics.errors.name, context.topics_errors)
    end
  end

  describe "#topics_consumers_commands" do
    it "returns the configured commands topic name" do
      assert_equal( Karafka::Web.config.topics.consumers.commands.name.to_s , context.topics_consumers_commands)
    end
  end

  describe "#topics_details" do
    context "when cluster_info is nil" do
      it "returns topics with default values" do
        details = context.topics_details

        assert_includes(details.keys, context.topics_consumers_states)
        assert_includes(details.keys, context.topics_consumers_reports)
        assert_includes(details.keys, context.topics_consumers_metrics)
        assert_includes(details.keys, context.topics_errors)

        details.each_value do |detail|
          refute(detail[:present])
          assert_equal(0, detail[:partitions])
          assert_equal(1, detail[:replication])
        end
      end
    end

    context "when cluster_info has topic data" do
      let(:cluster_info) do
        # cluster_info from ClusterInfo.fetch is an Rdkafka::Metadata object
        # that responds to #topics returning an array of hashes
        Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            }
          ]
        )
      end

      before { context.cluster_info = cluster_info }

      it "returns topics with actual values" do
        details = context.topics_details

        assert(details[context.topics_consumers_states][:present])
        assert_equal(1, details[context.topics_consumers_states][:partitions])
        assert_equal(3, details[context.topics_consumers_states][:replication])
      end
    end

    it "memoizes the result" do
      first_call = context.topics_details
      second_call = context.topics_details

      assert_same(second_call, first_call)
    end
  end

  describe "#clear_topics_details_cache" do
    it "clears the memoized topics_details" do
      first_call = context.topics_details
      context.clear_topics_details_cache
      second_call = context.topics_details

      refute_same(second_call, first_call)
    end
  end
end
