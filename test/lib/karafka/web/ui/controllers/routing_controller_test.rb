# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#index" do
    before { get "routing" }

    it do
      assert(response.ok?)
      assert_body(topics_config.consumers.states.name)
      assert_body(topics_config.consumers.metrics.name)
      assert_body(topics_config.consumers.reports.name)
      assert_body(topics_config.errors.name)
      assert_body("karafka_web")
      assert_body(breadcrumbs)
      assert_body(support_message)
    end
  end

  describe "#show" do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it "expect to display details, including the injectable once" do
      assert(response.ok?)
      assert_body("kafka.topic.metadata.refresh.interval.ms")
      assert_body(breadcrumbs)
      assert_body("kafka.statistics.interval.ms")
      assert_body(support_message)
    end

    context "when given route is not available" do
      before { get "routing/na" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are saml details" do
      before do
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            kafka(
              "sasl.username": "username",
              "sasl.password": "password",
              "sasl.mechanisms": "SCRAM-SHA-512",
              "bootstrap.servers": "127.0.0.1:9092"
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "expect to hide them" do
        assert(response.ok?)
        assert_body("kafka.sasl.username")
        assert_body("***")
        assert_body(support_message)
        assert_body(breadcrumbs)
      end
    end

    context "when there are ssl details" do
      before do
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            kafka(
              "ssl.key.password": "password",
              "bootstrap.servers": "127.0.0.1:9092"
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "expect to hide them" do
        assert(response.ok?)
        assert_body("kafka.ssl.key.password")
        assert_body("***")
        assert_body(support_message)
        assert_body(breadcrumbs)
      end
    end

    context "when topic has manual offset management" do
      before do
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            manual_offset_management true
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "displays manual offset management setting" do
        assert(response.ok?)
        assert_body("manual_offset_management")
        assert_body("true")
        assert_body(support_message)
        assert_body(breadcrumbs)
      end
    end

    context "when topic has complex configuration" do
      before do
        t_name = generate_topic_name

        draw_routes do
          topic t_name do
            consumer Karafka::BaseConsumer
            max_messages 100
            max_wait_time 1000
            initial_offset "earliest"
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "displays processing settings" do
        assert(response.ok?)
        assert_body("max_messages")
        assert_body("100")
        assert_body("max_wait_time")
        assert_body("1000")
        assert_body("initial_offset")
        assert_body("earliest")
        assert_body(support_message)
      end
    end

    context "when topic belongs to subscription group" do
      before do
        t_name = generate_topic_name

        draw_routes do
          subscription_group :critical do
            topic t_name do
              consumer Karafka::BaseConsumer
            end
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "displays subscription group information" do
        assert(response.ok?)
        assert_body("subscription_group_details.name")
        assert_body("critical")
        assert_body(support_message)
      end
    end
  end
end
