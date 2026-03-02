# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { assert_equal(false, described_class.independent?) }
    it { assert_equal(:topics, described_class.dependency) }
  end

  describe "#call" do
    context "when Karafka Pro is not enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(false) }

      it "returns success regardless of topic presence" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal(true, result.success?)
      end
    end

    context "when Karafka Pro is enabled" do
      before { allow(Karafka).to receive(:pro?).and_return(true) }

      context "when commands topic exists" do
        before do
          context.cluster_info = Struct.new(:topics).new(
            [
              {
                topic_name: context.topics_consumers_commands,
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

          assert_equal(context.topics_consumers_commands, result.details[:topic_name])
          assert_equal(true, result.details[:present])
        end
      end

      context "when commands topic does not exist" do
        before do
          context.cluster_info = Struct.new(:topics).new([])
        end

        it "returns warning" do
          result = check.call

          assert_equal(:warning, result.status)
          assert_equal(true, result.success?)
        end

        it "includes topic details" do
          result = check.call

          assert_equal(context.topics_consumers_commands, result.details[:topic_name])
          assert_equal(false, result.details[:present])
        end
      end
    end
  end
end
