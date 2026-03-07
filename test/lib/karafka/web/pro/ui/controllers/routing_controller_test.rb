# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  describe "#index" do
    context "when running against defaults" do
      before { get "routing" }

      it do
        assert(response.ok?)
        assert_body(topics_config.consumers.states.name)
        assert_body(topics_config.consumers.metrics.name)
        assert_body(topics_config.consumers.reports.name)
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
        refute_body(support_message)
      end
    end

    context "when there is no consumers state" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(false)

        get "routing"
      end

      it do
        assert(response.ok?)
        assert_body(topics_config.consumers.states.name)
        assert_body(topics_config.consumers.metrics.name)
        assert_body(topics_config.consumers.reports.name)
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
        refute_body(support_message)
      end
    end

    context "when there are states and reports" do
      let(:states_topic) { create_topic }
      let(:reports_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.reports.name = reports_topic

        report = Fixtures.consumers_reports_json
        scope = report[:consumer_groups][:example_app6_app][:subscription_groups][:c4ca4238a0b9_0]
        base = scope[:topics][:default][:partitions]

        5.times { |i| base[i + 1] = base[:"0"].dup.merge(id: i + 1) }

        produce(states_topic, Fixtures.consumers_states_file)
        produce(reports_topic, report.to_json)

        get "routing"
      end

      it do
        assert(response.ok?)
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
        refute_body(support_message)
      end
    end
  end

  describe "#show" do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it "expect to display details, including the injectable once" do
      assert(response.ok?)
      assert_body("kafka.topic.metadata.refresh.interval.ms")
      assert_body(breadcrumbs)
      assert_body("kafka.statistics.interval.ms")
      refute_body(support_message)
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
              "bootstrap.servers": "127.0.0.1:80"
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "expect to hide them" do
        assert(response.ok?)
        assert_body("kafka.sasl.username")
        assert_body("***")
        assert_body(breadcrumbs)
        refute_body(support_message)
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
              "bootstrap.servers": "127.0.0.1:80"
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "expect to hide them" do
        assert(response.ok?)
        assert_body("kafka.ssl.key.password")
        assert_body("***")
        assert_body(breadcrumbs)
        refute_body(support_message)
      end
    end
  end
end
