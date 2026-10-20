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

  %i[started_at cpus memory_usage workers tags execution_mode listeners cpu_usage].each do |key|
    context "when process #{key} is missing" do
      before { report[:process].delete(key) }

      it { refute(contract.call(report).success?) }
    end
  end

  %i[busy enqueued waiting utilization total].each do |key|
    context "when stats #{key} is missing" do
      before { report[:stats].delete(key) }

      it { refute(contract.call(report).success?) }
    end
  end

  context "when validating the consumer groups tree" do
    let(:cg) { report[:consumer_groups].values.first }
    let(:sg) { cg[:subscription_groups].values.first }
    let(:topic) { sg[:topics].values.first }
    let(:partition) { topic[:partitions].values.first }

    {
      cg: %i[id subscription_groups],
      sg: %i[id state topics],
      topic: %i[name partitions partitions_cnt],
      partition: %i[id lag_stored lag_stored_d]
    }.each do |level, keys|
      keys.each do |key|
        context "when #{level} #{key} is missing" do
          before { public_send(level).delete(key) }

          it { refute(contract.call(report).success?) }
        end
      end
    end

    context "when a consumer group is empty" do
      before { report[:consumer_groups] = { cg: {} } }

      it { refute(contract.call(report).success?) }
    end

    context "when a subscription group is empty" do
      before { cg[:subscription_groups] = { sg: {} } }

      it { refute(contract.call(report).success?) }
    end
  end

  context "when validating the jobs" do
    it { assert(contract.call(report).success?) }

    %i[consumer consumer_group topic partition first_offset updated_at status].each do |key|
      context "when job #{key} is missing" do
        before { report[:jobs].first.delete(key) }

        it { refute(contract.call(report).success?) }
      end
    end

    context "when a job is empty" do
      before { report[:jobs] = [{}] }

      it { refute(contract.call(report).success?) }
    end
  end

  context "when a version is missing" do
    before { report[:versions].delete(:karafka) }

    it { refute(contract.call(report).success?) }
  end

  context "when values are not the ones the Ruby tracking sends" do
    before do
      report[:process][:status] = "healthy"
      report[:process][:tags] = %w[go]
      report[:versions].transform_values! { "go-1.22" }
    end

    it { assert(contract.call(report).success?) }
  end
end
