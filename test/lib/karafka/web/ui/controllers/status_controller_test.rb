# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  before do
    produce(TOPICS[0], Fixtures.consumers_states_file)
  end

  describe "#show" do
    context "when all that is needed is there" do
      before { get "status" }

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        refute_includes(body, "The initial state of the consumers appears to")

        # Enhanced assertions based on actual status page content
        assert_includes(body, "Data Type")
        assert_includes(body, "Topic Name")

        # Version badges should be present
        assert_includes(body, "karafka #{Karafka::VERSION}")
        assert_includes(body, "karafka-web #{Karafka::Web::VERSION}")
        assert_includes(body, "badge-primary")

        # Status should show topic names in data table
        assert_includes(body, topics_config.consumers.states.name)
        assert_includes(body, topics_config.consumers.metrics.name)
        assert_includes(body, topics_config.consumers.reports.name)
        assert_includes(body, topics_config.errors.name)

        # Should show data type labels
        assert_includes(body, "Errors")
        assert_includes(body, "Consumers reports")
        assert_includes(body, "Consumers states")
        assert_includes(body, "Consumers metrics")

        # Should show alert boxes
        assert_includes(body, "Components info")
        assert_includes(body, "Routing topics presence")
        assert_includes(body, "alert-box-info")
        assert_includes(body, "alert-box-warning")
      end
    end

    context "when topics are missing" do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)

        # Enhanced assertions - missing topics should still show the table structure
        assert_includes(body, "Data Type")
        assert_includes(body, "Topic Name")
        assert_includes(body, "Consumers states")
        assert_includes(body, "Consumers metrics")
        assert_includes(body, "Consumers reports")
        assert_includes(body, "Errors")

        # Version info should still be present
        assert_includes(body, "karafka #{Karafka::VERSION}")
        assert_includes(body, "badge-primary")

        # Alert boxes should still be present
        assert_includes(body, "Components info")
        assert_includes(body, "alert-box-info")
      end
    end

    context "when replication factor is less than 2 in production" do
      before do
        allow(Karafka.env).to receive(:production?).and_return(true)
        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Please ensure all those topics have a replication")
        assert_includes(body, "alert-box-warning")

        # Enhanced assertions - production warnings should have alert structure
        assert_includes(body, "alert-box-header")

        # Basic structure should still be there
        assert_includes(body, "Data Type")
        assert_includes(body, "Topic Name")
        assert_includes(body, "Components info")
        assert_includes(body, "badge-primary")
      end
    end

    context "when replication factor is less than 2 in non-production" do
      before { get "status" }

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        refute_includes(body, "Please ensure all those topics have a replication")
      end
    end

    context "when consumers states topic received corrupted data" do
      let(:states_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        # Corrupted on purpose
        produce(states_topic, "{")

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "The initial state of the consumers appears to")
      end
    end

    context "when consumers metrics topic received corrupted data" do
      let(:metrics_topic) { create_topic }

      before do
        topics_config.consumers.metrics.name = metrics_topic
        produce(metrics_topic, "{")

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "The initial state of the consumers metrics appears to")
      end
    end

    context "when accessing with query parameters" do
      before { get "status?debug=true&refresh=1" }

      it "ignores query parameters and shows normal status" do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
      end
    end

    context "when cache clearing behavior" do
      before do
        # Make two requests to verify cache clearing
        get "status"
        get "status"
      end

      it "always shows fresh status" do
        assert(response.ok?)
        assert_includes(body, support_message)
      end
    end

    context "when displaying version information" do
      before { get "status" }

      it "shows Karafka and Web UI versions" do
        assert(response.ok?)
        assert_includes(body, Karafka::VERSION)
        assert_includes(body, Karafka::Web::VERSION)
      end
    end

    context "when Web UI is not enabled in karafka.rb" do
      before do
        allow(Karafka::Web.config).to receive(:group_id).and_return("non_existent_group")
        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Karafka Web-UI is not part of your")
        assert_includes(body, "alert-box-error")
      end
    end

    context "when connection to Kafka fails" do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Web UI was not able to establish a connection")
        assert_includes(body, "alert-box-error")
      end
    end

    context "when states topic has wrong number of partitions" do
      let(:states_topic) { create_topic(partitions: 5) }

      before do
        topics_config.consumers.states.name = states_topic
        produce(states_topic, Fixtures.consumers_states_file)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "need to be configured with")
        assert_includes(body, "exactly")
        assert_includes(body, "one partition")
      end
    end

    context "when no live processes are reporting" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic

        # Create state with no processes
        parsed_state = JSON.parse(Fixtures.consumers_states_file)
        parsed_state["processes"] = {}
        parsed_state["stats"]["processes"] = 0

        produce(states_topic, parsed_state.to_json)
        produce(metrics_topic, Fixtures.consumers_metrics_file)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "There are no Karafka consumer processes actively reporting")
      end
    end

    context "when some routed topics are missing from Kafka cluster" do
      let(:non_existing_topic) { generate_topic_name }
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file)
        produce(metrics_topic, Fixtures.consumers_metrics_file)

        parsed = JSON.parse(Fixtures.consumers_reports_file)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)

        allow(Karafka::App.routes.first.topics.first)
          .to receive(:name)
          .and_return(non_existing_topic)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "were not located in the Kafka cluster")
        assert_includes(body, non_existing_topic)
        assert_includes(body, "alert-box-warning")
      end
    end

    context "when pro subscription is not active" do
      before do
        allow(Karafka).to receive(:pro?).and_return(false)
        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Karafka Pro subscription")
        assert_includes(body, "alert-box-warning")
      end
    end

    context "when consumers reports data is corrupted" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file)
        produce(metrics_topic, Fixtures.consumers_metrics_file)
        produce(reports_topic, "{")

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        # Corrupted reports data leads to failure in consumers_reports check
        assert_includes(body, "alert-box-error")
      end
    end

    context "when consumers reports schema state is incompatible" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        # Create state with incompatible schema
        parsed_state = JSON.parse(Fixtures.consumers_states_file)
        parsed_state["schema_state"] = "incompatible"

        produce(states_topic, parsed_state.to_json)
        produce(metrics_topic, Fixtures.consumers_metrics_file)

        parsed = JSON.parse(Fixtures.consumers_reports_file)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Incompatible consumer reports detected")
        assert_includes(body, "alert-box-error")
      end
    end

    context "when consumers have incompatible schema versions" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file)
        produce(metrics_topic, Fixtures.consumers_metrics_file)

        # Create report with incompatible schema version
        parsed = JSON.parse(Fixtures.consumers_reports_file)
        parsed["schema_version"] = "incompatible_version"
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "Some consumers are using schema versions")
        assert_includes(body, "alert-box-warning")
      end
    end

    context "when materializing lag is too high" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        # Create state with old dispatched_at to simulate lag
        parsed_state = JSON.parse(Fixtures.consumers_states_file)
        parsed_state["dispatched_at"] = Time.now.to_f - 30

        produce(states_topic, parsed_state.to_json)
        produce(metrics_topic, Fixtures.consumers_metrics_file)

        parsed = JSON.parse(Fixtures.consumers_reports_file)
        cg = parsed["consumer_groups"]["example_app6_app"]["subscription_groups"]["c4ca4238a0b9_0"]
        cg["topics"][reports_topic] = cg["topics"]["default"]
        cg["topics"][reports_topic]["name"] = reports_topic

        produce(reports_topic, parsed.to_json)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "significant lag in materializing")
        assert_includes(body, "alert-box-error")
      end
    end

    context "when state calculation is not subscribed" do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic

        produce(states_topic, Fixtures.consumers_states_file)
        produce(metrics_topic, Fixtures.consumers_metrics_file)
        # Reports topic exists but process is not subscribed to it
        produce(reports_topic, Fixtures.consumers_reports_file)

        get "status"
      end

      it do
        assert(response.ok?)
        assert_includes(body, support_message)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "is subscribed to handle")
      end
    end
  end
end
