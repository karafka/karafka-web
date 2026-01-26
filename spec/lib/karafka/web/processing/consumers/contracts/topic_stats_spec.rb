# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:topic_stats) do
    {
      lag_hybrid: 5,
      pace: 3,
      ls_offset_fd: 2
    }
  end

  context "when all values are valid" do
    it "is valid" do
      expect(contract.call(topic_stats)).to be_success
    end
  end

  context "when lag_hybrid is not a number" do
    before { topic_stats[:lag_hybrid] = "test" }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when lag_hybrid is missing" do
    before { topic_stats.delete(:lag_hybrid) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when pace is not a number" do
    before { topic_stats[:pace] = "test" }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when pace is missing" do
    before { topic_stats.delete(:pace) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when ls_offset_fd is not a number" do
    before { topic_stats[:ls_offset_fd] = "test" }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when ls_offset_fd is less than 0" do
    before { topic_stats[:ls_offset_fd] = -2 }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end

  context "when ls_offset_fd is missing" do
    before { topic_stats.delete(:ls_offset_fd) }

    it { expect(contract.call(topic_stats)).not_to be_success }
  end
end
