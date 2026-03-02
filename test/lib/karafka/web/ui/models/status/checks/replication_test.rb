# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute_predicate(described_class, :independent?) }
    it { assert_equal(:partitions, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    context "when replication factor is adequate" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            },
            {
              topic_name: context.topics_consumers_reports,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            },
            {
              topic_name: context.topics_consumers_metrics,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            },
            {
              topic_name: context.topics_errors,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            }
          ]
        )
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_predicate(result, :success?)
      end
    end

    context "when replication factor is low in production" do
      before do
        allow(Karafka.env).to receive(:production?).and_return(true)
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
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns warning" do
        result = check.call

        assert_equal(:warning, result.status)
        assert_predicate(result, :success?)
      end
    end

    context "when replication factor is low in non-production" do
      before do
        allow(Karafka.env).to receive(:production?).and_return(false)
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
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns success (non-production allows low replication)" do
        result = check.call

        assert_equal(:success, result.status)
      end
    end
  end
end
