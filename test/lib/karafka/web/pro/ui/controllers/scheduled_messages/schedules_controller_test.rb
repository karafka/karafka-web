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

  describe "scheduled_messages/ path redirect" do
    context "when visiting the scheduled_messages/ path without type indicator" do
      before { get "scheduled_messages" }

      it "expect to redirect to running schedules page" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "scheduled_messages/schedules")
      end
    end
  end

  describe "#index" do
    let(:no_groups) { "We are unable to display data related to scheduled messages" }

    context "when there are no schedules in routes nor any topics" do
      before { get "scheduled_messages/schedules" }

      it do
        assert(response.ok?)
        assert_includes(body, no_groups)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there are schedules in routes but not created" do
      before do
        draw_routes do
          scheduled_messages("not_existing")
        end

        get "scheduled_messages/schedules"
      end

      it do
        assert(response.ok?)
        assert_includes(body, no_groups)
        assert_includes(body, breadcrumbs)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there is one schedule and routes exist" do
      let(:messages_topic) { create_topic }
      let(:states_topic) { create_topic(topic_name: "#{messages_topic}_states") }

      before do
        states_topic
        messages_topic_ref = messages_topic

        draw_routes do
          scheduled_messages(messages_topic_ref)
        end

        get "scheduled_messages/schedules"
      end

      it do
        assert(response.ok?)
        assert_includes(body, messages_topic)
        assert_includes(body, breadcrumbs)
        refute_includes(body, no_groups)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there are many schedules and routes exist" do
      let(:messages_topic1) { create_topic }
      let(:states_topic1) { create_topic(topic_name: "#{messages_topic1}_states") }
      let(:messages_topic2) { create_topic }
      let(:states_topic2) { create_topic(topic_name: "#{messages_topic2}_states") }

      before do
        states_topic1
        messages_topic_ref1 = messages_topic1
        states_topic2
        messages_topic_ref2 = messages_topic2

        draw_routes do
          scheduled_messages(messages_topic_ref1)
          scheduled_messages(messages_topic_ref2)
        end

        get "scheduled_messages/schedules"
      end

      it do
        assert(response.ok?)
        assert_includes(body, messages_topic1)
        assert_includes(body, messages_topic2)
        assert_includes(body, breadcrumbs)
        refute_includes(body, no_groups)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end
  end

  describe "#show" do
    let(:messages_topic) { create_topic }
    let(:states_topic) { create_topic(topic_name: "#{messages_topic}_states") }
    let(:no_states) { "No state information for this partition is available." }

    before do
      states_topic
      messages_topic_ref = messages_topic

      draw_routes do
        scheduled_messages(messages_topic_ref)
      end
    end

    context "when there are no states for any of the partitions" do
      before { get "scheduled_messages/schedules/#{messages_topic}" }

      it do
        assert(response.ok?)
        assert_includes(body, messages_topic)
        assert_includes(body, breadcrumbs)
        assert_includes(body, no_states)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end

    context "when there are state reports for partitions" do
      before do
        state = Fixtures.scheduled_messages_states_msg("current")
        produce(states_topic, state)

        get "scheduled_messages/schedules/#{messages_topic}"
      end

      it do
        assert(response.ok?)
        assert_includes(body, messages_topic)
        assert_includes(body, breadcrumbs)
        assert_includes(body, "2024-09-02")
        refute_includes(body, no_states)
        refute_includes(body, pagination)
        refute_includes(body, support_message)
      end
    end
  end
end
