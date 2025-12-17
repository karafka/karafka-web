# frozen_string_literal: true

RSpec.describe_current do
  subject(:status) { described_class.new }

  describe 'CHECKS registry' do
    it 'has all dependency references pointing to existing checks' do
      described_class::CHECKS.each do |name, check_class|
        next if check_class.independent?

        dependency = check_class.dependency
        next unless dependency

        expect(described_class::CHECKS).to have_key(
          dependency
        ), "Check #{name} depends on #{dependency.inspect} which is not registered in CHECKS"
      end
    end
  end

  let(:errors_topic) { Karafka::Web.config.topics.errors.name = create_topic }
  let(:reports_topic) { Karafka::Web.config.topics.consumers.reports.name = create_topic }
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:states_topic) { Karafka::Web.config.topics.consumers.states.name = create_topic }
  let(:state) { Fixtures.consumers_states_file }
  let(:metrics) { Fixtures.consumers_metrics_file }
  let(:report) { Fixtures.consumers_reports_file }

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

    it { expect(result.success?).to be(true) }
    it { expect(result.to_s).to eq('success') }
    it { expect(result.details).to eq({}) }
    it { expect(result.partial_namespace).to eq('successes') }

    context 'when routing does not include the web processing group' do
      before { allow(Karafka::Web.config).to receive(:group_id).and_return([]) }

      it { expect(result.success?).to be(false) }
      it { expect(result.to_s).to eq('failure') }
      it { expect(result.details).to eq({}) }
      it { expect(result.partial_namespace).to eq('failures') }
    end
  end

  describe '#connection' do
    subject(:result) { status.connection }

    context 'when routing is not enabled' do
      before { allow(Karafka::Web.config).to receive(:group_id).and_return([]) }

      it { expect(result.success?).to be(false) }
      it { expect(result.to_s).to eq('halted') }
      it { expect(result.details).to eq({ time: nil }) }
      it { expect(result.partial_namespace).to eq('failures') }
    end

    context 'when we can connect fast' do
      it { expect(result.success?).to be(true) }
      it { expect(result.to_s).to eq('success') }
      it { expect(result.details[:time]).not_to be_nil }
      it { expect(result.partial_namespace).to eq('successes') }
    end

    context 'when we cannot connect' do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))
      end

      it { expect(result.success?).to be(false) }
      it { expect(result.to_s).to eq('failure') }
      it { expect(result.details[:time]).not_to be_nil }
      it { expect(result.partial_namespace).to eq('failures') }
    end
  end

  describe '#topics' do
    subject(:result) { status.topics }

    context 'when there is no connection' do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))
      end

      it { expect(result.success?).to be(false) }
      it { expect(result.to_s).to eq('halted') }
      it { expect(result.details).to eq({}) }
      it { expect(result.partial_namespace).to eq('failures') }
    end

    context 'when all topics exist' do
      before { all_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_nil
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when error topic is missing' do
      let(:na_topic) { generate_topic_name }

      before do
        Karafka::Web.config.topics.errors.name = na_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect not to be successful' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details[na_topic][:present]).to be(false)
        expect(result.details[reports_topic][:present]).to be(true)
        expect(result.details[reports_topic][:partitions]).to eq(1)
        expect(result.details[metrics_topic][:present]).to be(true)
        expect(result.details[metrics_topic][:partitions]).to eq(1)
        expect(result.details[states_topic][:present]).to be(true)
        expect(result.details[states_topic][:partitions]).to eq(1)
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when metrics topic is missing' do
      let(:na_topic) { generate_topic_name }

      before do
        Karafka::Web.config.topics.consumers.metrics.name = na_topic
        errors_topic
        reports_topic
        states_topic
      end

      it 'expect not to be successful' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details[na_topic][:present]).to be(false)
        expect(result.details[reports_topic][:present]).to be(true)
        expect(result.details[reports_topic][:partitions]).to eq(1)
        expect(result.details[errors_topic][:present]).to be(true)
        expect(result.details[errors_topic][:partitions]).to eq(1)
        expect(result.details[states_topic][:present]).to be(true)
        expect(result.details[states_topic][:partitions]).to eq(1)
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#partitions' do
    subject(:result) { status.partitions }

    context 'when not all topics are there' do
      before { Karafka::Web.config.topics.errors.name = generate_topic_name }

      it { expect(result.success?).to be(false) }
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
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there are many error partitions' do
      before do
        Karafka::Web.config.topics.errors.name = create_topic(partitions: 5)
        reports_topic
        metrics_topic
        states_topic
      end

      it 'expect to have everything in order' do
        expect(result.success?).to be(true)
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
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it 'expect to fail and report' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#replication' do
    subject(:result) { status.replication }

    context 'when partitions check failed' do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when all topics have adequate replication' do
      before { all_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when replication is low in production' do
      before do
        all_topics
        allow(Karafka.env).to receive(:production?).and_return(true)
      end

      it 'expect to warn' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('warning')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('warnings')
      end
    end

    context 'when replication is low in non-production' do
      before do
        all_topics
        allow(Karafka.env).to receive(:production?).and_return(false)
      end

      it 'expect all to be ok because non-production is acceptable' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).not_to be_empty
        expect(result.partial_namespace).to eq('successes')
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
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({ issue_type: :presence })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when initial state is not present' do
      before { all_topics }

      it 'expect to fail' do
        expect(result.success?).to be(false)
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
        expect(result.success?).to be(true)
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
        expect(result.success?).to be(false)
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
        allow(Karafka.env).to receive(:production?).and_return(true)
      end

      it 'expect all to be ok because replication is a warning' do
        expect(result.success?).to be(true)
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
        expect(result.success?).to be(false)
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
        expect(result.success?).to be(false)
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({ issue_type: :deserialization })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when state and metrics are present' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when at least one process is active' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when at least one process is active' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#consumers_schemas' do
    subject(:result) { status.consumers_schemas }

    context 'when consumers_reports check failed' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
        produce(reports_topic, '{')
      end

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({ incompatible: [] })
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when all consumer schemas are compatible' do
      before { ready_topics }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details[:incompatible]).to be_empty
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when some consumer schemas are incompatible' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        # Modify the report to have an incompatible schema version
        parsed = JSON.parse(report)
        parsed['schema_version'] = 'incompatible_version'

        produce(reports_topic, parsed.to_json)
      end

      it 'expect to warn' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('warning')
        expect(result.details[:incompatible]).not_to be_empty
        expect(result.partial_namespace).to eq('warnings')
      end
    end
  end

  describe '#materializing_lag' do
    subject(:result) { status.materializing_lag }

    context 'when there is no live reporting' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq(lag: 0, max_lag: 10)
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
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when there is live reporting but state computation is lagging' do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed['consumer_groups']['example_app6_app']['subscription_groups']['c4ca4238a0b9_0']
        cg['topics'][reports_topic] = cg['topics']['default']
        cg['topics'][reports_topic]['name'] = reports_topic
        produce(reports_topic, parsed.to_json)

        parsed_state = JSON.parse(state)
        # simulate reporting lag
        parsed_state['dispatched_at'] = Time.now.to_f - 15
        produce(states_topic, parsed_state.to_json)
      end

      it 'expect all to be ok' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.partial_namespace).to eq('failures')
        expect(result[:details][:lag]).to be > 10
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when there is live reporting and no state calculation' do
      before { ready_topics }

      it 'expect to report failure' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('successes')
      end
    end
  end

  describe '#consumers_reports_schema_state' do
    subject(:result) { status.consumers_reports_schema_state }

    context 'when there is no state computation' do
      before { ready_topics }

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
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
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('failure')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('failures')
      end
    end
  end

  describe '#routing_topics_presence' do
    subject(:result) { status.routing_topics_presence }

    context 'when there is no state computation' do
      before { ready_topics }

      it 'expect to halt' do
        expect(result.success?).to be(false)
        expect(result.to_s).to eq('halted')
        expect(result.details).to eq([])
        expect(result.partial_namespace).to eq('failures')
      end
    end

    context 'when checks steps are satisfied' do
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

      context 'when all topics are present' do
        before do
          routes = Karafka::App.routes
          # We are interested only in stubbing the result on the last execution
          allow(Karafka::App).to receive(:routes).and_return(routes, routes, routes, [])
        end

        it 'expect all to be ok' do
          expect(result.success?).to be(true)
          expect(result.to_s).to eq('success')
          expect(result.details).to eq([])
          expect(result.partial_namespace).to eq('successes')
        end
      end

      context 'when some routing topics are missing' do
        let(:non_existing_topic) { generate_topic_name }

        before do
          allow(Karafka::App.routes.first.topics.first)
            .to receive(:name)
            .and_return(non_existing_topic)
        end

        it 'expect to warn' do
          expect(result.success?).to be(true)
          expect(result.to_s).to eq('warning')
          expect(result.details).to include(non_existing_topic)
          expect(result.partial_namespace).to eq('warnings')
        end
      end
    end
  end

  describe '#pro_subscription' do
    subject(:result) { status.pro_subscription }

    context 'when pro is on' do
      before { allow(Karafka).to receive(:pro?).and_return(true) }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('success')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('successes')
      end
    end

    context 'when pro is off' do
      before { allow(Karafka).to receive(:pro?).and_return(false) }

      it 'expect all to be ok' do
        expect(result.success?).to be(true)
        expect(result.to_s).to eq('warning')
        expect(result.details).to eq({})
        expect(result.partial_namespace).to eq('warnings')
      end
    end
  end
end
