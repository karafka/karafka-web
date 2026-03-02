# frozen_string_literal: true

describe_current do
  let(:stats) { described_class.new(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:errors_topic) { create_topic }

  before { Karafka::Web.config.topics.errors.name = errors_topic }

  context "when errors topic does not exist" do
    it "expect to have zero errors and loaded other stats" do
      assert_equal(0, stats[:errors])
      assert_equal(0, stats.errors)
      assert_equal(16_351, stats.batches)
      assert_equal(0, stats.dead)
      assert_equal(2, stats.processes)
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
