# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  describe "#index" do
    context "when running against defaults" do
      before { get "routing" }

      it do
        assert_ok
        assert_body(topics_config.consumers.states.name)
        assert_body(topics_config.consumers.metrics.name)
        assert_body(topics_config.consumers.reports.name)
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
      end
    end

    context "when filtering by a matching topic name" do
      # A rendered consumer group table always contains the "Subscription group" header, so we use
      # it (rather than the topic name, which is echoed back in the filter input regardless) as the
      # reliable signal that at least one group actually rendered
      before { get "routing?filter=#{Karafka::App.routes.first.topics.first.name}" }

      it do
        assert_ok
        assert_body("Subscription group")
      end
    end

    context "when filtering by a matching consumer group name" do
      before { get "routing?filter=#{Karafka::App.routes.first.id}" }

      it do
        assert_ok
        # Matching the group name keeps the whole group (its topics) visible
        assert_body("Subscription group")
        assert_body(Karafka::App.routes.first.topics.first.name)
      end
    end

    context "when scoping the filter to the consumer group field" do
      before do
        get "routing?filter[field]=consumer_group&filter[value]=#{Karafka::App.routes.first.id}"
      end

      it do
        assert_ok
        # The group matches, so its table renders, and the selected field is reflected in the select
        assert_body("Subscription group")
        assert_body('name="filter[field]"')
        assert_body('value="consumer_group" selected')
      end
    end

    context "when filtering by a non-matching keyword" do
      before { get "routing?filter=zzz-nonexistent-topic-zzz" }

      it do
        assert_ok
        # No topic or group matches, so all consumer groups are hidden (no table rendered), but the
        # filter box remains alongside the filter-specific empty state
        assert_body('name="filter[value]"')
        assert_body("No results match your filter")
        refute_body("Subscription group")
      end

      it "does not mutate the live app routing" do
        topic_names = -> { Karafka::App.routes.flat_map { |cg| cg.topics.map(&:name) }.sort }

        before_topics = topic_names.call
        get "routing?filter=zzz-nonexistent-topic-zzz"
        after_topics = topic_names.call

        assert_equal(before_topics, after_topics)
      end
    end

    context "when there is no consumers state" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(false)

        get "routing"
      end

      it do
        assert_ok
        assert_body(topics_config.consumers.states.name)
        assert_body(topics_config.consumers.metrics.name)
        assert_body(topics_config.consumers.reports.name)
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
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
        assert_ok
        assert_body(topics_config.errors.name)
        assert_body("karafka_web")
        assert_body(breadcrumbs)
      end
    end
  end

  describe "#show" do
    before { get "routing/#{Karafka::App.routes.first.topics.first.id}" }

    it "expect to display details, including the injectable once" do
      assert_ok
      assert_body("kafka.topic.metadata.refresh.interval.ms")
      assert_body(breadcrumbs)
      assert_body("kafka.statistics.interval.ms")
    end

    context "when sorting the details by attribute name" do
      before { get "routing/#{Karafka::App.routes.first.topics.first.id}?sort=name+desc" }

      it do
        assert_ok
        assert_body("kafka.topic.metadata.refresh.interval.ms")
      end
    end

    context "when sorting the details by value" do
      before { get "routing/#{Karafka::App.routes.first.topics.first.id}?sort=value+desc" }

      it do
        assert_ok
        assert_body("kafka.topic.metadata.refresh.interval.ms")
      end
    end

    context "when filtering the details by attribute name" do
      before do
        get "routing/#{Karafka::App.routes.first.topics.first.id}" \
            "?filter[field]=name&filter[value]=statistics"
      end

      it do
        assert_ok
        assert_body("kafka.statistics.interval.ms")
        refute_body("kafka.topic.metadata.refresh.interval.ms")
      end
    end

    context "when filtering the details by a non-matching keyword" do
      before do
        get "routing/#{Karafka::App.routes.first.topics.first.id}" \
            "?filter=zzz-nonexistent-attribute-zzz"
      end

      it do
        assert_ok
        assert_body("No results match your filter")
      end
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
        assert_ok
        assert_body("kafka.sasl.username")
        assert_body("***")
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
              "bootstrap.servers": "127.0.0.1:80"
            )
          end
        end

        get "routing/#{Karafka::App.routes.last.topics.last.id}"
      end

      it "expect to hide them" do
        assert_ok
        assert_body("kafka.ssl.key.password")
        assert_body("***")
        assert_body(breadcrumbs)
      end
    end
  end
end
