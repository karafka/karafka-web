# frozen_string_literal: true

RSpec.describe_current do
  subject(:stats) { described_class.new(state) }

  let(:state) { Fixtures.consumers_states_json }
  let(:errors_topic) { create_topic }

  before { Karafka::Web.config.topics.errors.name = errors_topic }

  context "when errors topic does not exist" do
    it "expect to have zero errors and loaded other stats" do
      expect(stats[:errors]).to eq(0)
      expect(stats.errors).to eq(0)
      expect(stats.batches).to eq(16_351)
      expect(stats.dead).to eq(0)
      expect(stats.processes).to eq(2)
    end
  end

  describe "#pending" do
    before do
      state[:stats][:enqueued] = 5
      state[:stats][:waiting] = 7
    end

    it "expect to sum enqueued and waiting" do
      expect(stats.pending).to eq(12)
    end
  end
end
