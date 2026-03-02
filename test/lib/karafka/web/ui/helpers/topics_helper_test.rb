# frozen_string_literal: true

describe_current do
  let(:helper_class) do
    Class.new do
      include Karafka::Web::Ui::Helpers::TopicsHelper
    end
  end

  let(:helper) { helper_class.new }

  describe "#topics_assignment_text" do
    context "when partitions array is empty" do
      it "returns just the topic name" do
        result = helper.topics_assignment_text("user-events", [])
        assert_equal("user-events", result)
      end

      it "handles nil partitions" do
        result = helper.topics_assignment_text("user-events", nil)
        assert_equal("user-events", result)
      end
    end

    context "when there is a single partition" do
      it "returns topic with single partition in brackets" do
        result = helper.topics_assignment_text("user-events", [0])
        assert_equal("user-events-[0]", result)
      end

      it "handles single partition as integer" do
        result = helper.topics_assignment_text("user-events", 5)
        assert_equal("user-events-[5]", result)
      end

      it "handles string partition numbers" do
        result = helper.topics_assignment_text("user-events", ["3"])
        assert_equal("user-events-[3]", result)
      end
    end

    context "when there are multiple consecutive partitions" do
      it "returns range format for 3+ consecutive partitions" do
        result = helper.topics_assignment_text("user-events", [0, 1, 2, 3])
        assert_equal("user-events-[0-3]", result)
      end

      it "returns comma format for exactly 2 consecutive partitions" do
        result = helper.topics_assignment_text("user-events", [0, 1])
        assert_equal("user-events-[0,1]", result)
      end

      it "handles unsorted consecutive partitions" do
        result = helper.topics_assignment_text("user-events", [3, 1, 2, 0])
        assert_equal("user-events-[0-3]", result)
      end

      it "handles string partition numbers in consecutive range" do
        result = helper.topics_assignment_text("user-events", %w[0 1 2 3 4])
        assert_equal("user-events-[0-4]", result)
      end
    end

    context "when there are multiple non-consecutive partitions" do
      it "returns comma-separated list" do
        result = helper.topics_assignment_text("user-events", [0, 2, 4])
        assert_equal("user-events-[0,2,4]", result)
      end

      it "sorts partitions before displaying" do
        result = helper.topics_assignment_text("user-events", [4, 0, 2])
        assert_equal("user-events-[0,2,4]", result)
      end

      it "handles mixed string and integer partitions" do
        result = helper.topics_assignment_text("user-events", ["4", 0, "2"])
        assert_equal("user-events-[0,2,4]", result)
      end
    end

    context "when partitions exceed the limit" do
      it "truncates and shows ellipsis with default limit" do
        partitions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10]
        result = helper.topics_assignment_text("user-events", partitions)
        assert_equal("user-events-[0,1,2,3,4...]", result)
      end

      it "respects custom limit parameter" do
        partitions = [0, 1, 2, 3, 4, 10]
        result = helper.topics_assignment_text("user-events", partitions, limit: 3)
        assert_equal("user-events-[0,1,2...]", result)
      end

      it "does not truncate when partitions count equals limit" do
        partitions = [0, 1, 2, 3, 5]
        result = helper.topics_assignment_text("user-events", partitions, limit: 5)
        assert_equal("user-events-[0,1,2,3,5]", result)
      end

      it "prioritizes consecutive range over truncation" do
        partitions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        result = helper.topics_assignment_text("user-events", partitions, limit: 3)
        assert_equal("user-events-[0-9]", result)
      end
    end

    context "when limit is nil" do
      it "shows all partitions without truncation" do
        partitions = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
        result = helper.topics_assignment_text("user-events", partitions, limit: nil)
        assert_equal("user-events-[0,2,4,6,8,10,12,14,16,18]", result)
      end
    end

    context "with edge cases" do
      it "handles negative partition numbers" do
        result = helper.topics_assignment_text("user-events", [-1, 0, 1])
        assert_equal("user-events-[-1-1]", result)
      end

      it "handles large partition numbers" do
        result = helper.topics_assignment_text("user-events", [100, 101, 102])
        assert_equal("user-events-[100-102]", result)
      end
    end
  end

  describe "#topics_assignment_label" do
    context "when partitions are consecutive" do
      it "returns range format with partition count" do
        result = helper.topics_assignment_label("user-events", [0, 1, 2, 3])
        assert_equal("user-events-[0-3] (4 partitions total)", result)
      end

      it "works with just 2 consecutive partitions" do
        result = helper.topics_assignment_label("user-events", [5, 6])
        assert_equal("user-events-[5-6] (2 partitions total)", result)
      end

      it "handles unsorted consecutive partitions" do
        result = helper.topics_assignment_label("user-events", [3, 1, 2, 0, 4])
        assert_equal("user-events-[0-4] (5 partitions total)", result)
      end
    end

    context "when partitions exceed the limit" do
      it "shows truncated list with remaining count using default limit" do
        partitions = [0, 2, 4, 6, 8, 10, 12]
        result = helper.topics_assignment_label("user-events", partitions)
        assert_equal("user-events-[0,2,4,6,8] (+2 more)", result)
      end

      it "respects custom limit parameter" do
        partitions = [0, 2, 4, 6, 8, 10]
        result = helper.topics_assignment_label("user-events", partitions, limit: 2)
        assert_equal("user-events-[0,2] (+4 more)", result)
      end

      it 'does not show "more" when count equals limit' do
        partitions = [0, 2, 4, 6, 8]
        result = helper.topics_assignment_label("user-events", partitions, limit: 5)
        assert_equal("user-events-[0,2,4,6,8]", result)
      end
    end

    context "when partitions are non-consecutive and within limit" do
      it "returns comma-separated list" do
        result = helper.topics_assignment_label("user-events", [0, 2, 4])
        assert_equal("user-events-[0,2,4]", result)
      end

      it "sorts partitions before displaying" do
        result = helper.topics_assignment_label("user-events", [4, 0, 2])
        assert_equal("user-events-[0,2,4]", result)
      end
    end

    context "with edge cases" do
      it "handles single partition" do
        result = helper.topics_assignment_label("user-events", [5])
        assert_equal("user-events-[5]", result)
      end

      it "handles empty partitions array" do
        result = helper.topics_assignment_label("user-events", [])
        assert_equal("user-events-[]", result)
      end

      it "handles string partition numbers" do
        result = helper.topics_assignment_label("user-events", %w[0 1 2])
        assert_equal("user-events-[0-2] (3 partitions total)", result)
      end
    end
  end

  describe "#topics_partition_identifier" do
    it "returns topic and partition separated by dash" do
      result = helper.topics_partition_identifier("user-events", 0)
      assert_equal("user-events-0", result)
    end

    it "handles string partition numbers" do
      result = helper.topics_partition_identifier("user-events", "5")
      assert_equal("user-events-5", result)
    end

    it "handles topics with special characters" do
      result = helper.topics_partition_identifier("user_events.v1", 3)
      assert_equal("user_events.v1-3", result)
    end

    it "handles negative partition numbers" do
      result = helper.topics_partition_identifier("user-events", -1)
      assert_equal("user-events--1", result)
    end

    it "handles large partition numbers" do
      result = helper.topics_partition_identifier("user-events", 999)
      assert_equal("user-events-999", result)
    end
  end

  describe "#topics_consecutive?" do
    context "when array contains consecutive numbers" do
      it "returns true for simple consecutive sequence" do
        result = helper.send(:topics_consecutive?, [1, 2, 3, 4])
        assert_equal(true, result)
      end

      it "returns true for two consecutive numbers" do
        result = helper.send(:topics_consecutive?, [5, 6])
        assert_equal(true, result)
      end

      it "returns true for consecutive sequence starting from zero" do
        result = helper.send(:topics_consecutive?, [0, 1, 2])
        assert_equal(true, result)
      end

      it "returns true for consecutive negative numbers" do
        result = helper.send(:topics_consecutive?, [-2, -1, 0, 1])
        assert_equal(true, result)
      end
    end

    context "when array contains non-consecutive numbers" do
      it "returns false for non-consecutive sequence" do
        result = helper.send(:topics_consecutive?, [1, 3, 5, 7])
        assert_equal(false, result)
      end

      it "returns false for mostly consecutive with one gap" do
        result = helper.send(:topics_consecutive?, [1, 2, 4, 5])
        assert_equal(false, result)
      end

      it "returns false for reverse order" do
        result = helper.send(:topics_consecutive?, [4, 3, 2, 1])
        assert_equal(false, result)
      end
    end

    context "when array has insufficient elements" do
      it "returns false for single element" do
        result = helper.send(:topics_consecutive?, [1])
        assert_equal(false, result)
      end

      it "returns false for empty array" do
        result = helper.send(:topics_consecutive?, [])
        assert_equal(false, result)
      end
    end

    context "with edge cases" do
      it "returns false for duplicate consecutive numbers" do
        result = helper.send(:topics_consecutive?, [1, 1, 2, 3])
        assert_equal(false, result)
      end

      it "handles large consecutive numbers" do
        result = helper.send(:topics_consecutive?, [100, 101, 102, 103])
        assert_equal(true, result)
      end
    end
  end

  describe "DEFAULT_LIMIT constant" do
    it "is set to 5" do
      assert_equal(5, described_class::DEFAULT_LIMIT)
    end
  end

  describe "integration scenarios" do
    context "when testing real-world topic names" do
      it "handles complex topic names" do
        topic = "com.example.user-events.v2"
        partitions = [0, 1, 2, 3, 4]

        text_result = helper.topics_assignment_text(topic, partitions)
        label_result = helper.topics_assignment_label(topic, partitions)

        assert_equal("com.example.user-events.v2-[0-4]", text_result)
        assert_equal("com.example.user-events.v2-[0-4] (5 partitions total)", label_result)
      end
    end

    context "when having mixed scenarios" do
      it "handles large partition ranges correctly" do
        partitions = (0..20).to_a
        result = helper.topics_assignment_text("large-topic", partitions)
        assert_equal("large-topic-[0-20]", result)
      end

      it "handles sparse partition distribution" do
        partitions = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
        result = helper.topics_assignment_text("sparse-topic", partitions)
        assert_equal("sparse-topic-[0,10,20,30,40...]", result)
      end
    end
  end
end
