# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }
  let(:report) { Fixtures.consumers_reports_json }

  context "when the report is valid" do
    it { assert(contract.call(report).success?) }
  end

  %i[
    schema_version
    dispatched_at
    type
    versions
    stats
    consumer_groups
    jobs
    process
  ].each do |key|
    context "when #{key} is missing" do
      before { report.delete(key) }

      it { refute(contract.call(report).success?) }
    end
  end

  %i[id status].each do |key|
    context "when process #{key} is missing" do
      before { report[:process].delete(key) }

      it { refute(contract.call(report).success?) }
    end
  end

  context "when the type is not consumer" do
    before { report[:type] = "producer" }

    it { refute(contract.call(report).success?) }
  end

  context "when consumer_groups is not a hash" do
    before { report[:consumer_groups] = [] }

    it { refute(contract.call(report).success?) }
  end

  context "when Ruby-only process details are missing" do
    before do
      %i[cpus memory_usage memory_total_usage tags execution_mode].each do |key|
        report[:process].delete(key)
      end

      report[:versions] = {}
    end

    it { assert(contract.call(report).success?) }
  end
end
