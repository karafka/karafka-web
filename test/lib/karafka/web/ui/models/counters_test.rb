# frozen_string_literal: true

describe_current do
  let(:stats) { described_class.new(state) }
  let(:state) { Fixtures.consumers_states_json }

  describe "#errors" do
    context "when errors topic does not exist in Kafka" do
      before { Karafka::Web.config.topics.errors.name = generate_topic_name }

      it "expect to return zero" do
        assert_equal(0, stats.errors)
      end
    end

    context "when errors topic exists but has no messages" do
      let(:errors_topic) { create_topic }

      before { Karafka::Web.config.topics.errors.name = errors_topic }

      it "expect to return zero errors and load other stats from state correctly" do
        assert_equal(0, stats[:errors])
        assert_equal(0, stats.errors)
        assert_equal(16_351, stats.batches)
        assert_equal(0, stats.dead)
        assert_equal(2, stats.processes)
      end
    end

    context "when errors topic has messages in a single partition" do
      let(:errors_topic) { create_topic }

      before do
        Karafka::Web.config.topics.errors.name = errors_topic
        produce_many(errors_topic, Array.new(5) { SecureRandom.uuid })
      end

      it "expect to return the correct message count" do
        assert_equal(5, stats.errors)
      end
    end

    context "when errors topic has multiple partitions with messages" do
      let(:errors_topic) { create_topic(partitions: 3) }

      before do
        Karafka::Web.config.topics.errors.name = errors_topic
        produce_many(errors_topic, Array.new(3) { SecureRandom.uuid }, partition: 0)
        produce_many(errors_topic, Array.new(4) { SecureRandom.uuid }, partition: 1)
        produce_many(errors_topic, Array.new(2) { SecureRandom.uuid }, partition: 2)
      end

      it "expect to return the sum across all partitions" do
        assert_equal(9, stats.errors)
      end
    end
  end

  describe "#pending" do
    before do
      state[:stats][:enqueued] = 5
      state[:stats][:waiting] = 7
    end

    it "expect to sum enqueued and waiting" do
      assert_equal(12, stats.pending)
    end
  end
end
