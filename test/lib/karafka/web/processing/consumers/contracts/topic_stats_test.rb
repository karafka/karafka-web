# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  let(:topic_stats) do
    {
      lag_hybrid: 5,
      pace: 3,
      ls_offset_fd: 2
    }
  end

  context "when all values are valid" do
    it "is valid" do
      assert_predicate(contract.call(topic_stats), :success?)
    end
  end

  context "when lag_hybrid is not a number" do
    before { topic_stats[:lag_hybrid] = "test" }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when lag_hybrid is missing" do
    before { topic_stats.delete(:lag_hybrid) }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when pace is not a number" do
    before { topic_stats[:pace] = "test" }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when pace is missing" do
    before { topic_stats.delete(:pace) }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when ls_offset_fd is not a number" do
    before { topic_stats[:ls_offset_fd] = "test" }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when ls_offset_fd is less than 0" do
    before { topic_stats[:ls_offset_fd] = -2 }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end

  context "when ls_offset_fd is missing" do
    before { topic_stats.delete(:ls_offset_fd) }

    it { refute_predicate(contract.call(topic_stats), :success?) }
  end
end
