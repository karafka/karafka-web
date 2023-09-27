# frozen_string_literal: true

RSpec.describe_current do
  subject(:status) { described_class.new }

  let(:errors_topic) { Karafka::Web.config.topics.errors = create_topic }
  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states = create_topic }
  let(:state) { Fixtures.file('consumers_state.json') }
  let(:metrics) { Fixtures.file('consumers_metrics.json') }
  let(:report) { Fixtures.file('consumer_report.json') }

  let(:all_topics) do
    errors_topic
    reports_topic
    metrics_topic
    states_topic
  end

  let(:ready_topics) do
    all_topics
    produce(states_topic, state)
    produce(metrics_topic, metrics)
    produce(reports_topic, report)
  end

  describe '#enabled' do
    subject(:result) { status.enabled }

    it { expect(result.success?).to eq(true) }
    it { expect(result.to_s).to eq('success') }
    it { expect(result.details).to eq(nil) }
    it { expect(result.partial_namespace).to eq('successes') }

    context 'when routing does not include the web processing group' do
      before { allow(::Karafka::Web.config.processing).to receive(:consumer_group).and_return([]) }

      it { expect(result.success?).to eq(false) }
      it { expect(result.to_s).to eq('failure') }
      it { expect(result.details).to eq(nil) }
      it { expect(result.partial_namespace).to eq('failures') }
    end
  end

  describe '#connection' do
    subject(:result) { status.connection }

    context 'when routing is not enabled' do
      before { allow(::Karafka::Web.config.processing).to receive(:consumer_group).and_return([]) }

      it { expect(result.success?).to eq(false) }
      it { expect(result.to_s).to eq('halted') }
      it { expect(result.details).to eq({ time: nil }) }
      it { expect(result.partial_namespace).to eq('failures') }
    end

    context 'when we can connect fast' do
      it { expect(result.success?).to eq(true) }
      it { expect(result.to_s).to eq('success') }
      it { expect(result.details[:time]).not_to eq(nil) }
      it { expect(result.partial_namespace).to eq('successes') }
    end

    context 'when we cannot connect' do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(::Rdkafka::RdkafkaError.new(0))
      end

      it { expect(result.success?).to eq(false) }
      it { expect(result.to_s).to eq('failure') }
      it { expect(result.details[:time]).not_to eq(nil) }
      it { expect(result.partial_namespace).to eq('failures') }
    end
  end

  describe '#topics' do
    subject(:result) { status.topics }

    context 'when there is no connection' do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(::Rdkafka::RdkafkaError.new(0))
      end

      it { expect(result.success?).to eq(false) }
      it { expect(result.to_s).to eq('halted') }
      it { expect(result.details).to eq({}) }
      it { expect(result.partial_namespace).to eq('failures') }
    end

    context 'when all topics exist' do
      before { all_topics }

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_nil
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when error topic is missing' do
      let(:na_topic) { SecureRandom.uuid }

      before do
        Karafka::Web.config.topics.errors = na_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect not to be successful' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details[na_topic][:present]).to eq(false)
        expect(result.details[reports_topic][:present]).to eq(true)
        expect(result.details[reports_topic][:partitions]).to eq(1)
        expect(result.details[metrics_topic][:present]).to eq(true)
        expect(result.details[metrics_topic][:partitions]).to eq(1)
        expect(result.details[states_topic][:present]).to eq(true)
        expect(result.details[states_topic][:partitions]).to eq(1)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when metrics topic is missing' do
      let(:na_topic) { SecureRandom.uuid }

      before do
        Karafka::Web.config.topics.consumers.metrics = na_topic
        errors_topic
        reports_topic
        states_topic
      end

      it 'expect not to be successful' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details[na_topic][:present]).to eq(false)
        expect(result.details[reports_topic][:present]).to eq(true)
        expect(result.details[reports_topic][:partitions]).to eq(1)
        expect(result.details[errors_topic][:present]).to eq(true)
        expect(result.details[errors_topic][:partitions]).to eq(1)
        expect(result.details[states_topic][:present]).to eq(true)
        expect(result.details[states_topic][:partitions]).to eq(1)
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#partitions' do
    subject(:result) { status.partitions }

    context 'when not all topics are there' do
      before { Karafka::Web.config.topics.errors = SecureRandom.uuid }

      it { expect(result.success?).to eq(false) }
      it { expect(result.to_s).to eq('halted') }
      it { expect(result.details).to eq({}) }
      it { expect(result.partial_namespace).to eq('failures') }
    end

    context 'when all topics have required number of partitions' do
      before do
        errors_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect to have everything in order' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there are many error partitions' do
      before do
        Karafka::Web.config.topics.errors = create_topic(partitions: 5)
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect to have everything in order' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there are many states partitions' do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states = create_topic(partitions: 5)
      end

      it 'expect to fail and report' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#initial_consumers_state' do
    subject(:result) { status.initial_consumers_state }

    context 'when not all partitions are in order' do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states = create_topic(partitions: 5)
      end

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when initial state is not present' do
      before { all_topics }

      it 'expect to fail' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when state is present' do
      before do
        all_topics
        produce(states_topic, state)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when state is present but corrupted' do
      before do
        all_topics
        produce(states_topic, '{')
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({ issue_type: :deserialization })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when state is present but replication factor is 1 in prod' do
      before do
        all_topics
        produce(states_topic, state)
        # This will force a warning because in prod replication is expected to be > 1
        allow(Karafka.env).to receive(:production).and_return(true)
      end

      it 'expect all to be ok because replication is a warning' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('successes')
      end
    end
  end

  describe '#initial_consumers_metrics' do
    subject(:result) { status.initial_consumers_metrics }

    context 'when there is no initial consumers state' do
      before do
        errors_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when initial consumers metrics are not present' do
      before do
        all_topics
        produce(states_topic, state)
      end

      it 'expect to fail' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when initial consumers metrics are present but corrupted' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, '{')
      end

      it 'expect to fail' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({ issue_type: :deserialization })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when state and metrics are present' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('successes')
      end
    end
  end

  describe '#consumers_reports' do
    subject(:result) { status.consumers_reports }

    context 'when there is no initial consumers metrics state' do
      before do
        all_topics
        produce(states_topic, state)
      end

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when at least one process is active' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there are no processes' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when process data is corrupted' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
        produce(reports_topic, '{')
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#live_reporting' do
    subject(:result) { status.live_reporting }

    context 'when initial metrics state is corrupted' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, '{')
      end

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when at least one process is active' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there are no processes' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#state_calculation' do
    subject(:result) { status.state_calculation }

    context 'when there is no live reporting' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when there is live reporting and no state calculation' do
      before { ready_topics }

      it 'expect to report failure' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when there is live reporting and state calculation' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end
  end

  describe '#consumers_reports_schema_state' do
    subject(:result) { status.consumers_reports_schema_state }

    context 'when there is no state computation' do
      before { ready_topics }

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when the schema state is compatible' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when the schema state is not compatible' do
      before do
        all_topics

        parsed = JSON.parse(state)
        parsed['schema_state'] = 'incompatible'

        produce(states_topic, parsed.to_json)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#pro_subscription' do
    subject(:result) { status.pro_subscription }

    context 'when there is no state computation' do
      before { ready_topics }

      it 'expect to halt' do
        expect(result.success?).to eq(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when pro is on' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic

        produce(reports_topic, parsed.to_json)

        allow(Karafka).to receive(:pro?).and_return(true)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when pro is off' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it 'expect all to be ok' do
        expect(result.success?).to eq(true)
        expect(result.to_s).to eq('warning')
        expect(result.details).to eq(nil)
        expect(result.partial_namespace).to eq('warnings')
      end
    end
  end
end
