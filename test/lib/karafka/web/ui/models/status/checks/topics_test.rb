# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { assert_equal(false, described_class.independent?) }
    it { assert_equal(:connection, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    context "when all topics exist" do
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
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal(true, result.success?)
      end

      it "includes topic details" do
        result = check.call

        assert_equal(true, result.details[context.topics_consumers_states][:present])
        assert_equal(true, result.details[context.topics_consumers_reports][:present])
      end
    end

    context "when some topics are missing" do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 1 }]
            }
          ]
        )
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(false, result.success?)
      end

      it "shows which topics are missing" do
        result = check.call

        assert_equal(true, result.details[context.topics_consumers_states][:present])
        assert_equal(false, result.details[context.topics_consumers_reports][:present])
      end
    end
  end
end
