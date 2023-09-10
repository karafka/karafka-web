# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:report) do
    {
      schema_version: '1.2.0',
      type: 'consumer',
      dispatched_at: 1_687_439_240.493,
      process: process,
      versions: versions,
      stats: stats,
      consumer_groups: consumer_groups,
      jobs: []
    }
  end

  let(:stats) do
    {
      busy: 0,
      enqueued: 0,
      utilization: 0.006,
      total: {
        batches: 1,
        messages: 1,
        errors: 0,
        retries: 0,
        dead: 0
      }
    }
  end

  let(:process) do
    {
      started_at: 1_687_439_150.1767561,
      name: 'shinra:3548178:324ae2b47a12',
      status: 'running',
      listeners: 2,
      workers: 2,
      threads: 10,
      memory_usage: 103_364,
      memory_total_usage: 22_637_828,
      memory_size: 32_783_440,
      cpus: 8,
      cpu_usage: [2.9, 1.69, 1.47],
      tags: ::Karafka::Core::Taggable::Tags.new
    }
  end

  let(:consumer_groups) do
    {
      'example_app_karafka_web' => {
        id: 'example_app_karafka_web',
        subscription_groups: {
          'c81e728d9d4c_1' => {
            id: 'c81e728d9d4c_1',
            state: {
              state: 'up',
              join_state: 'steady',
              stateage: 90_002,
              rebalance_age: 90_000,
              rebalance_cnt: 1,
              rebalance_reason: 'Metadata for subscribed topic(s) has changed'
            },
            topics: {
              'karafka_consumers_reports' => {
                name: 'karafka_consumers_reports',
                partitions: {
                  0 => {
                    lag_stored: 0,
                    lag_stored_d: 0,
                    lag: 0,
                    lag_d: 0,
                    committed_offset: 18,
                    stored_offset: 18,
                    fetch_state: 'active',
                    id: 0,
                    poll_state: 'active',
                    hi_offset: 1,
                    lo_offset: 0,
                    eof_offset: 0,
                    ls_offset: 0,
                    ls_offset_d: 0,
                    ls_offset_fd: 0
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  let(:versions) do
    {
      ruby: 'ruby 3.2.2-53 e51014',
      karafka: '2.1.5',
      waterdrop: '2.6.1',
      karafka_core: '2.1.0',
      karafka_web: '1.0.0',
      rdkafka: '0.13.0',
      librdkafka: '2.0.2'
    }
  end

  context 'when config is valid' do
    it { expect(contract.call(report)).to be_success }
  end

  context 'when dispatched_at is not a number' do
    before { report[:dispatched_at] = 'test' }

    it { expect(contract.call(report)).not_to be_success }
  end

  %i[schema_version type].each do |attr|
    context "when #{attr} is missing" do
      before { report.delete(attr) }

      it { expect(contract.call(report)).not_to be_success }
    end

    context "when #{attr} is empty" do
      before { report[attr] = '' }

      it { expect(contract.call(report)).not_to be_success }
    end

    context "when #{attr} is not a string" do
      before { report[attr] = 123 }

      it { expect(contract.call(report)).not_to be_success }
    end
  end

  %i[
    started_at name memory_usage memory_total_usage memory_size status listeners workers tags
    cpu_usage threads cpus
  ].each do |attr|
    context "when process.#{attr} is missing" do
      before { report[:process].delete(attr) }

      it { expect(contract.call(report)).not_to be_success }
    end
  end

  %i[ruby karafka karafka_core karafka_web waterdrop rdkafka librdkafka].each do |attr|
    context "when versions.#{attr} is missing" do
      before { report[:versions].delete(attr) }

      it { expect(contract.call(report)).not_to be_success }
    end
  end

  %i[busy enqueued utilization].each do |attr|
    context "when stats.#{attr} is missing" do
      before { report[:stats].delete(attr) }

      it { expect(contract.call(report)).not_to be_success }
    end
  end

  %i[batches messages errors retries dead].each do |attr|
    context "when stats.total.#{attr} is missing" do
      before { report[:stats][:total].delete(attr) }

      it { expect(contract.call(report)).not_to be_success }
    end
  end

  context 'when consumer_groups is missing' do
    before { report.delete(:consumer_groups) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.started_at is missing' do
    before { report[:process].delete(:started_at) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.started_at is not a numeric' do
    before { report[:process][:started_at] = 'not_numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.started_at is negative' do
    before { report[:process][:started_at] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.name is missing' do
    before { report[:process].delete(:name) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.name is not a string' do
    before { report[:process][:name] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.name does not contain at least two colons' do
    before { report[:process][:name] = 'name_without_colons' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_usage is missing' do
    before { report[:process].delete(:memory_usage) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_usage is not an integer' do
    before { report[:process][:memory_usage] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_usage is negative' do
    before { report[:process][:memory_usage] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_total_usage is missing' do
    before { report[:process].delete(:memory_total_usage) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_total_usage is not an integer' do
    before { report[:process][:memory_total_usage] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_total_usage is negative' do
    before { report[:process][:memory_total_usage] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_size is missing' do
    before { report[:process].delete(:memory_size) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_size is not an integer' do
    before { report[:process][:memory_size] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.memory_size is negative' do
    before { report[:process][:memory_size] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.status is missing' do
    before { report[:process].delete(:status) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.status is not a string' do
    before { report[:process][:status] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.status is not a key in ::Karafka::Status::STATES' do
    before { report[:process][:status] = 'not_a_state' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.listeners is missing' do
    before { report[:process].delete(:listeners) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.listeners is not an integer' do
    before { report[:process][:listeners] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.listeners is negative' do
    before { report[:process][:listeners] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.workers is missing' do
    before { report[:process].delete(:workers) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.workers is not an integer' do
    before { report[:process][:workers] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.workers is non-positive' do
    before { report[:process][:workers] = 0 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.threads is missing' do
    before { report[:process].delete(:threads) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.threads is not an integer' do
    before { report[:process][:threads] = 'not_an_integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.threads is non-positive' do
    before { report[:process][:threads] = 0 }

    it { expect(contract.call(report)).to be_success }
  end

  context 'when process.tags is missing' do
    before { report[:process].delete(:tags) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.tags is not an instance of Karafka::Core::Taggable::Tags' do
    before { report[:process][:tags] = 'not_a_tags_instance' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.cpu_usage is missing' do
    before { report[:process].delete(:cpu_usage) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.cpu_usage is not an array' do
    before { report[:process][:cpu_usage] = 'not_an_array' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.cpu_usage is an array containing non-numeric values' do
    before { report[:process][:cpu_usage] = [1, 'not_a_number', 3] }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.cpu_usage is an array containing negative values' do
    before { report[:process][:cpu_usage] = [1, -2, 3] }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when process.cpu_usage array size is not equal to 3' do
    before { report[:process][:cpu_usage] = [1, 2] }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.ruby is missing' do
    before { report[:versions].delete(:ruby) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.ruby is not a string' do
    before { report[:versions][:ruby] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.ruby is empty' do
    before { report[:versions][:ruby] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka is missing' do
    before { report[:versions].delete(:karafka) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka is not a string' do
    before { report[:versions][:karafka] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka is empty' do
    before { report[:versions][:karafka] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_core is missing' do
    before { report[:versions].delete(:karafka_core) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_core is not a string' do
    before { report[:versions][:karafka_core] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_core is empty' do
    before { report[:versions][:karafka_core] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_web is missing' do
    before { report[:versions].delete(:karafka_web) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_web is not a string' do
    before { report[:versions][:karafka_web] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.karafka_web is empty' do
    before { report[:versions][:karafka_web] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.waterdrop is missing' do
    before { report[:versions].delete(:waterdrop) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.waterdrop is not a string' do
    before { report[:versions][:waterdrop] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.waterdrop is empty' do
    before { report[:versions][:waterdrop] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.rdkafka is missing' do
    before { report[:versions].delete(:rdkafka) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.rdkafka is not a string' do
    before { report[:versions][:rdkafka] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.rdkafka is empty' do
    before { report[:versions][:rdkafka] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.librdkafka is missing' do
    before { report[:versions].delete(:librdkafka) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.librdkafka is not a string' do
    before { report[:versions][:librdkafka] = 123 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when versions.librdkafka is empty' do
    before { report[:versions][:librdkafka] = '' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.busy is missing' do
    before { report[:stats].delete(:busy) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.busy is not an integer' do
    before { report[:stats][:busy] = 'not an integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.busy is negative' do
    before { report[:stats][:busy] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.enqueued is missing' do
    before { report[:stats].delete(:enqueued) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.enqueued is not an integer' do
    before { report[:stats][:enqueued] = 'not an integer' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.enqueued is negative' do
    before { report[:stats][:enqueued] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.utilization is missing' do
    before { report[:stats].delete(:utilization) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.utilization is not a numeric' do
    before { report[:stats][:utilization] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.utilization is negative' do
    before { report[:stats][:utilization] = -0.1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.batches is missing' do
    before { report[:stats][:total].delete(:batches) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.batches is not a numeric' do
    before { report[:stats][:total][:batches] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.batches is negative' do
    before { report[:stats][:total][:batches] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.messages is missing' do
    before { report[:stats][:total].delete(:messages) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.messages is not a numeric' do
    before { report[:stats][:total][:messages] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.messages is negative' do
    before { report[:stats][:total][:messages] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.errors is missing' do
    before { report[:stats][:total].delete(:errors) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.errors is not a numeric' do
    before { report[:stats][:total][:errors] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.errors is negative' do
    before { report[:stats][:total][:errors] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.retries is missing' do
    before { report[:stats][:total].delete(:retries) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.retries is not a numeric' do
    before { report[:stats][:total][:retries] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.retries is negative' do
    before { report[:stats][:total][:retries] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.dead is missing' do
    before { report[:stats][:total].delete(:dead) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.dead is not a numeric' do
    before { report[:stats][:total][:dead] = 'not a numeric' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when stats.total.dead is negative' do
    before { report[:stats][:total][:dead] = -1 }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when consumer_groups is not an array' do
    before { report[:consumer_groups] = 'not an array' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when jobs is missing' do
    before { report.delete(:jobs) }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when jobs is not an array' do
    before { report[:jobs] = 'not an array' }

    it { expect(contract.call(report)).not_to be_success }
  end

  context 'when jobs exist but are not valid' do
    before { report[:jobs] = [{ valid: false }] }

    it { expect { contract.call(report) }.to raise_error(Karafka::Web::Errors::ContractError) }
  end
end
