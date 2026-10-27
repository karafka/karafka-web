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

  context "when the type is not consumer" do
    before { report[:type] = "producer" }

    it { refute(contract.call(report).success?) }
  end

  context "when consumer_groups is not a hash" do
    before { report[:consumer_groups] = [] }

    it { refute(contract.call(report).success?) }
  end

  %i[
    id status started_at cpus memory_usage workers tags execution_mode listeners cpu_usage
  ].each do |key|
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

  context "when a version is missing" do
    before { report[:versions].delete(:karafka) }

    it { refute(contract.call(report).success?) }
  end

  context "when validating the consumer groups tree" do
    let(:cg) { report[:consumer_groups].values.first }
    let(:sg) { cg[:subscription_groups].values.first }
    let(:topic) { sg[:topics].values.first }
    let(:partition) { topic[:partitions].values.first }

    let(:sg_state) { sg[:state] }

    {
      cg: %i[id subscription_groups],
      sg: %i[id instance_id state topics],
      sg_state: %i[join_state rebalance_reason stateage rebalance_age rebalance_cnt poll_age],
      topic: %i[name partitions partitions_cnt],
      partition: %i[
        id lag lag_d lag_stored lag_stored_d committed_offset stored_offset hi_offset ls_offset
        ls_offset_fd poll_state_ch fetch_state poll_state
      ]
    }.each do |level, keys|
      keys.each do |key|
        context "when #{level} #{key} is missing" do
          before { public_send(level).delete(key) }

          it { refute(contract.call(report).success?) }
        end
      end
    end

    context "when a partition key is missing" do
      before { partition.delete(:lag) }

      it "names the missing key" do
        path = [
          :consumer_groups, report[:consumer_groups].keys.first,
          :subscription_groups, cg[:subscription_groups].keys.first,
          :topics, sg[:topics].keys.first,
          :partitions, topic[:partitions].keys.first,
          :lag
        ].join(".").to_sym

        assert_equal({ path => "needs to be present" }, contract.call(report).errors)
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
    %i[consumer consumer_group topic partition first_offset updated_at status].each do |key|
      context "when job #{key} is missing" do
        before { report[:jobs].first.delete(key) }

        it { refute(contract.call(report).success?) }
      end
    end

    context "when a job key is missing" do
      before { report[:jobs].first.delete(:topic) }

      it { assert_equal({ "jobs.0.topic": "needs to be present" }, contract.call(report).errors) }
    end

    context "when a job is empty" do
      before { report[:jobs] = [{}] }

      it { refute(contract.call(report).success?) }
    end
  end

  context "when the report is built by the Ruby tracking" do
    let(:report) do
      consumer_groups = Fixtures.consumers_reports_json[:consumer_groups]

      subscription_groups = consumer_groups.values.flat_map do |cg|
        cg[:subscription_groups].keys
      end

      now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

      tracking = subscription_groups.to_h do |sg_id|
        [
          sg_id,
          { polled_at: now - 12.345, poll_interval: 300_000, instance_id: false, topics: {} }
        ]
      end

      sampled = Karafka::Web::Tracking::Consumers::Sampler.new.to_report
      sampled[:consumer_groups] = Karafka::Web::Tracking::Consumers::Sampler::Enrichers::ConsumerGroups
        .new(consumer_groups, tracking)
        .call

      JSON.parse(sampled.to_json, symbolize_names: true)
    end

    let(:sg_state) do
      report[:consumer_groups].values.first[:subscription_groups].values.first[:state]
    end

    it { assert_kind_of(Float, sg_state[:poll_age]) }
    it { assert(contract.call(report).success?) }
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
