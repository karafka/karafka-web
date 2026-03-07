# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:topics, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    context "when all topics have correct partition count" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_reports,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_metrics,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_errors,
              partition_count: 5,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert(result.success?)
      end
    end

    context "when states topic has wrong partition count" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 5,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_reports,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_metrics,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_errors,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        refute(result.success?)
      end
    end

    context "when reports topic has wrong partition count" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_reports,
              partition_count: 3,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_metrics,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_errors,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
      end
    end

    context "when metrics topic has wrong partition count" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_reports,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_consumers_metrics,
              partition_count: 2,
              partitions: [{ replica_count: 1 }]
            },
            {
              topic_name: context.topics_errors,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
      end
    end
  end
end
