# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }
  let(:report) { { dispatched_at: Time.now.to_f, process: { id: "shinra:1:1" } } }

  context "when the report has what the registration reads" do
    it { assert(contract.call(report).success?) }
  end

  context "when dispatched_at is missing" do
    before { report.delete(:dispatched_at) }

    it { refute(contract.call(report).success?) }
  end

  context "when the process id is missing" do
    before { report[:process].delete(:id) }

    it { refute(contract.call(report).success?) }
  end

  context "when the process is not a hash" do
    before { report[:process] = "shinra:1:1" }

    it { refute(contract.call(report).success?) }
  end
end
