# frozen_string_literal: true

describe_current do
  let(:partition) { described_class.new(data) }

  let(:hi_offset) { 100 }
  let(:ls_offset) { 100 }
  let(:ls_offset_fd) { 100 }
  let(:committed_offset) { 100 }
  let(:lag_stored) { -1 }
  let(:lag) { 100 }

  let(:data) do
    {
      hi_offset: hi_offset,
      ls_offset: ls_offset,
      ls_offset_fd: ls_offset_fd,
      committed_offset: committed_offset,
      lag_stored: lag_stored,
      lag_stored_d: 0,
      lag: lag,
      lag_d: 2
    }
  end

  describe "#lag_hybrid and #lag_hybrid_d" do
    context "when lag stored is negative" do
      it { assert_equal(100, partition.lag_hybrid) }
      it { assert_equal(2, partition.lag_hybrid_d) }
    end

    context "when lag stored is positive" do
      let(:lag_stored) { 20 }

      it { assert_equal(20, partition.lag_hybrid) }
      it { assert_equal(0, partition.lag_hybrid_d) }
    end
  end

  describe "#lso_risk_state" do
    let(:lso_risk_state) { partition.lso_risk_state }

    context "when ls_offset is not behind hi_offset" do
      it { assert_equal(:active, lso_risk_state) }
    end

    context "when ls_offset behind hi_offset but within threshold" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 5 }

      it { assert_equal(:active, lso_risk_state) }
    end

    context "when ls_offset behind hi_offset behind threshold but we are not there" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 10 * 60 * 1_000 }
      let(:committed_offset) { ls_offset - 10 }

      it { assert_equal(:at_risk, lso_risk_state) }
    end

    context "when ls_offset behind hi_offset behind threshold and we are there" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 10 * 60 * 1_000 }
      let(:committed_offset) { ls_offset }

      it { assert_equal(:stopped, lso_risk_state) }
    end
  end
end
