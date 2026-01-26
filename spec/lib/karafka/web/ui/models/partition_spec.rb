# frozen_string_literal: true

RSpec.describe_current do
  subject(:partition) { described_class.new(data) }

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
      it { expect(partition.lag_hybrid).to eq(100) }
      it { expect(partition.lag_hybrid_d).to eq(2) }
    end

    context "when lag stored is positive" do
      let(:lag_stored) { 20 }

      it { expect(partition.lag_hybrid).to eq(20) }
      it { expect(partition.lag_hybrid_d).to eq(0) }
    end
  end

  describe "#lso_risk_state" do
    let(:lso_risk_state) { partition.lso_risk_state }

    context "when ls_offset is not behind hi_offset" do
      it { expect(lso_risk_state).to eq(:active) }
    end

    context "when ls_offset behind hi_offset but within threshold" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 5 }

      it { expect(lso_risk_state).to eq(:active) }
    end

    context "when ls_offset behind hi_offset behind threshold but we are not there" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 10 * 60 * 1_000 }
      let(:committed_offset) { ls_offset - 10 }

      it { expect(lso_risk_state).to eq(:at_risk) }
    end

    context "when ls_offset behind hi_offset behind threshold and we are there" do
      let(:hi_offset) { 100 }
      let(:ls_offset) { 60 }
      let(:ls_offset_fd) { 10 * 60 * 1_000 }
      let(:committed_offset) { ls_offset }

      it { expect(lso_risk_state).to eq(:stopped) }
    end
  end
end
