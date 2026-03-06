# frozen_string_literal: true

describe_current do
  let(:status) { described_class.new }

  describe "CHECKS registry" do
    it "has all dependency references pointing to existing checks" do
      described_class::CHECKS.each do |name, check_class|
        next if check_class.independent?

        dependency = check_class.dependency
        next unless dependency

        assert(described_class::CHECKS.key?(dependency),
          "Check #{name} depends on #{dependency.inspect} which is not registered in CHECKS")
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

  describe "#enabled" do
    let(:result) { status.enabled }

    it { assert(result.success?) }
    it { assert_equal("success", result.to_s) }
    it { assert_equal({}, result.details) }
    it { assert_equal("successes", result.partial_namespace) }

    context "when routing does not include the web processing group" do
      before { allow(Karafka::Web.config).to receive(:group_id).and_return([]) }

      it { refute(result.success?) }
      it { assert_equal("failure", result.to_s) }
      it { assert_equal({}, result.details) }
      it { assert_equal("failures", result.partial_namespace) }
    end
  end

  describe "#connection" do
    let(:result) { status.connection }

    context "when routing is not enabled" do
      before { allow(Karafka::Web.config).to receive(:group_id).and_return([]) }

      it { refute(result.success?) }
      it { assert_equal("halted", result.to_s) }
      it { assert_equal({ time: nil }, result.details) }
      it { assert_equal("failures", result.partial_namespace) }
    end

    context "when we can connect fast" do
      it { assert(result.success?) }
      it { assert_equal("success", result.to_s) }
      it { refute_nil(result.details[:time]) }
      it { assert_equal("successes", result.partial_namespace) }
    end

    context "when we cannot connect" do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))
      end

      it { refute(result.success?) }
      it { assert_equal("failure", result.to_s) }
      it { refute_nil(result.details[:time]) }
      it { assert_equal("failures", result.partial_namespace) }
    end
  end

  describe "#topics" do
    let(:result) { status.topics }

    context "when there is no connection" do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))
      end

      it { refute(result.success?) }
      it { assert_equal("halted", result.to_s) }
      it { assert_equal({}, result.details) }
      it { assert_equal("failures", result.partial_namespace) }
    end

    context "when all topics exist" do
      before { all_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        refute_nil(result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when error topic is missing" do
      let(:na_topic) { generate_topic_name }

      before do
        Karafka::Web.config.topics.errors.name = na_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it "expect not to be successful" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        refute(result.details[na_topic][:present])
        assert(result.details[reports_topic][:present])
        assert_equal(1, result.details[reports_topic][:partitions])
        assert(result.details[metrics_topic][:present])
        assert_equal(1, result.details[metrics_topic][:partitions])
        assert(result.details[states_topic][:present])
        assert_equal(1, result.details[states_topic][:partitions])
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when metrics topic is missing" do
      let(:na_topic) { generate_topic_name }

      before do
        Karafka::Web.config.topics.consumers.metrics.name = na_topic
        errors_topic
        reports_topic
        states_topic
      end

      it "expect not to be successful" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        refute(result.details[na_topic][:present])
        assert(result.details[reports_topic][:present])
        assert_equal(1, result.details[reports_topic][:partitions])
        assert(result.details[errors_topic][:present])
        assert_equal(1, result.details[errors_topic][:partitions])
        assert(result.details[states_topic][:present])
        assert_equal(1, result.details[states_topic][:partitions])
        assert_equal("failures", result.partial_namespace)
      end
    end
  end

  describe "#partitions" do
    let(:result) { status.partitions }

    context "when not all topics are there" do
      before { Karafka::Web.config.topics.errors.name = generate_topic_name }

      it { refute(result.success?) }
      it { assert_equal("halted", result.to_s) }
      it { assert_equal({}, result.details) }
      it { assert_equal("failures", result.partial_namespace) }
    end

    context "when all topics have required number of partitions" do
      before do
        errors_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it "expect to have everything in order" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        refute_empty(result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when there are many error partitions" do
      before do
        Karafka::Web.config.topics.errors.name = create_topic(partitions: 5)
        reports_topic
        metrics_topic
        states_topic
      end

      it "expect to have everything in order" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        refute_empty(result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when there are many states partitions" do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it "expect to fail and report" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        refute_empty(result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end
  end

  describe "#replication" do
    let(:result) { status.replication }

    context "when partitions check failed" do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when all topics have adequate replication" do
      before { all_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        refute_empty(result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when replication is low in production" do
      before do
        all_topics
        allow(Karafka.env).to receive(:production?).and_return(true)
      end

      it "expect to warn" do
        assert(result.success?)
        assert_equal("warning", result.to_s)
        refute_empty(result.details)
        assert_equal("warnings", result.partial_namespace)
      end
    end

    context "when replication is low in non-production" do
      before do
        all_topics
        allow(Karafka.env).to receive(:production?).and_return(false)
      end

      it "expect all to be ok because non-production is acceptable" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        refute_empty(result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end
  end

  describe "#initial_consumers_state" do
    let(:result) { status.initial_consumers_state }

    context "when not all partitions are in order" do
      before do
        errors_topic
        reports_topic
        metrics_topic
        Karafka::Web.config.topics.consumers.states.name = create_topic(partitions: 5)
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when initial state is not present" do
      before { all_topics }

      it "expect to fail" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when state is present" do
      before do
        all_topics
        produce(states_topic, state)
      end

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when state is present but corrupted" do
      before do
        all_topics
        produce(states_topic, "{")
      end

      it "expect all to be ok" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({ issue_type: :deserialization }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when state is present but replication factor is 1 in prod" do
      before do
        all_topics
        produce(states_topic, state)
        # This will force a warning because in prod replication is expected to be > 1
        allow(Karafka.env).to receive(:production?).and_return(true)
      end

      it "expect all to be ok because replication is a warning" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end
  end

  describe "#initial_consumers_metrics" do
    let(:result) { status.initial_consumers_metrics }

    context "when there is no initial consumers state" do
      before do
        errors_topic
        reports_topic
        metrics_topic
        states_topic
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when initial consumers metrics are not present" do
      before do
        all_topics
        produce(states_topic, state)
      end

      it "expect to fail" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when initial consumers metrics are present but corrupted" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, "{")
      end

      it "expect to fail" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({ issue_type: :deserialization }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when state and metrics are present" do
      before { ready_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({ issue_type: :presence }, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end
  end

  describe "#consumers_reports" do
    let(:result) { status.consumers_reports }

    context "when there is no initial consumers metrics state" do
      before do
        all_topics
        produce(states_topic, state)
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when at least one process is active" do
      before { ready_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when there are no processes" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when process data is corrupted" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
        produce(reports_topic, "{")
      end

      it "expect all to be ok" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end
  end

  describe "#live_reporting" do
    let(:result) { status.live_reporting }

    context "when initial metrics state is corrupted" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, "{")
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when at least one process is active" do
      before { ready_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when there are no processes" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it "expect all to be ok" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end
  end

  describe "#consumers_schemas" do
    let(:result) { status.consumers_schemas }

    context "when consumers_reports check failed" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
        produce(reports_topic, "{")
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({ incompatible: [] }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when all consumer schemas are compatible" do
      before { ready_topics }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_empty(result.details[:incompatible])
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when some consumer schemas are incompatible" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        # Modify the report to have an incompatible schema version
        parsed = JSON.parse(report)
        parsed["schema_version"] = "incompatible_version"

        produce(reports_topic, parsed.to_json)
      end

      it "expect to warn" do
        assert(result.success?)
        assert_equal("warning", result.to_s)
        refute_empty(result.details[:incompatible])
        assert_equal("warnings", result.partial_namespace)
      end
    end
  end

  describe "#materializing_lag" do
    let(:result) { status.materializing_lag }

    context "when there is no live reporting" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({ lag: 0, max_lag: 10 }, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when there is live reporting and state calculation" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when there is live reporting but state computation is lagging" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic
        produce(reports_topic, parsed.to_json)

        parsed_state = JSON.parse(state)
        # simulate reporting lag
        parsed_state["dispatched_at"] = Time.now.to_f - 15
        produce(states_topic, parsed_state.to_json)
      end

      it "expect all to be ok" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal("failures", result.partial_namespace)
        assert(result[:details][:lag] > 10)
      end
    end
  end

  describe "#state_calculation" do
    let(:result) { status.state_calculation }

    context "when there is no live reporting" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)
      end

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when there is live reporting and no state calculation" do
      before { ready_topics }

      it "expect to report failure" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when there is live reporting and state calculation" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end
  end

  describe "#consumers_reports_schema_state" do
    let(:result) { status.consumers_reports_schema_state }

    context "when there is no state computation" do
      before { ready_topics }

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when the schema state is compatible" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when the schema state is not compatible" do
      before do
        all_topics

        parsed = JSON.parse(state)
        parsed["schema_state"] = "incompatible"

        produce(states_topic, parsed.to_json)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      it "expect all to be ok" do
        refute(result.success?)
        assert_equal("failure", result.to_s)
        assert_equal({}, result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end
  end

  describe "#routing_topics_presence" do
    let(:result) { status.routing_topics_presence }

    context "when there is no state computation" do
      before { ready_topics }

      it "expect to halt" do
        refute(result.success?)
        assert_equal("halted", result.to_s)
        assert_equal([], result.details)
        assert_equal("failures", result.partial_namespace)
      end
    end

    context "when checks steps are satisfied" do
      before do
        all_topics
        produce(states_topic, state)
        produce(metrics_topic, metrics)

        parsed = JSON.parse(report)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)
      end

      context "when all topics are present" do
        before do
          routes = Karafka::App.routes
          # We are interested only in stubbing the result on the last execution
          allow(Karafka::App).to receive(:routes).and_return(routes, routes, routes, [])
        end

        it "expect all to be ok" do
          assert(result.success?)
          assert_equal("success", result.to_s)
          assert_equal([], result.details)
          assert_equal("successes", result.partial_namespace)
        end
      end

      context "when some routing topics are missing" do
        let(:non_existing_topic) { generate_topic_name }

        before do
          allow(Karafka::App.routes.first.topics.first)
            .to receive(:name)
            .and_return(non_existing_topic)
        end

        it "expect to warn" do
          assert(result.success?)
          assert_equal("warning", result.to_s)
          assert_includes(result.details, non_existing_topic)
          assert_equal("warnings", result.partial_namespace)
        end
      end
    end
  end

  describe "#pro_subscription" do
    let(:result) { status.pro_subscription }

    context "when pro is on" do
      before { allow(Karafka).to receive(:pro?).and_return(true) }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("success", result.to_s)
        assert_equal({}, result.details)
        assert_equal("successes", result.partial_namespace)
      end
    end

    context "when pro is off" do
      before { allow(Karafka).to receive(:pro?).and_return(false) }

      it "expect all to be ok" do
        assert(result.success?)
        assert_equal("warning", result.to_s)
        assert_equal({}, result.details)
        assert_equal("warnings", result.partial_namespace)
      end
    end
  end
end
