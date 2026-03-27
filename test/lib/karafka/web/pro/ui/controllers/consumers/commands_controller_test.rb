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

  let(:commands_topic) { create_topic }
  let(:no_commands) { "No commands found." }

  describe "#index" do
    context "when commands topic does not exist" do
      before do
        topics_config.consumers.commands.name = generate_topic_name

        get "consumers/commands"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no commands" do
      before do
        topics_config.consumers.commands.name = commands_topic

        get "consumers/commands"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body(no_commands)
      end
    end

    context "when command is with a schema that does not match system one" do
      before do
        topics_config.consumers.commands.name = commands_topic
        data = Fixtures.consumers_commands_json("consumers/current")
        data[:schema_version] = "0.0.1"
        produce(commands_topic, data.to_json)
        get "consumers/commands"
      end

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_commands)
        refute_body(pagination)
        refute_body('<span class="badge badge-primary">')
        refute_body("/consumers/shinra:1404842:f66b40c75f92/subscriptions")
        refute_body("/commands/0")
        assert_body(breadcrumbs)
        assert_body("Incompatible command schema.")
      end
    end

    context "when there are active commands" do
      before { get "consumers/commands" }

      it do
        assert(response.ok?)
        refute_body(support_message)
        refute_body(no_commands)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body('<span class="badge badge-primary">')
        assert_body("command")
        assert_body("quiet")
        assert_body("process_id:")
        assert_body("/commands/0")
      end
    end

    context "when there are more commands that we fit in a single page" do
      before do
        topics_config.consumers.commands.name = commands_topic

        34.times do
          %w[
            trace
            stop
            quiet
          ].each do |type|
            data = Fixtures.consumers_commands_json(
              "consumers/v1.2.0_#{type}",
              symbolize_names: false
            )
            id = SecureRandom.uuid
            data["matchers"]["process_id"] = id
            produce(commands_topic, data.to_json)
          end
        end
      end

      context "when we visit first page" do
        before { get "consumers/commands" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          refute_body(support_message)
          assert_body("commands/99")
          assert_body("trace")
          assert_body("quiet")
          assert_body("stop")
        end
      end

      context "when we visit second page" do
        before { get "consumers/commands/overview?offset=52" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          refute_body(support_message)
          assert_body("commands/53")
          refute_body("commands/99")
          assert_body("trace")
          assert_body("quiet")
          assert_body("stop")
          refute_body(support_message)
        end
      end

      context "when we go beyond available offsets" do
        before { get "consumers/commands/overview?offset=200" }

        it do
          assert(response.ok?)
          refute_body(pagination)
          assert_body(no_commands)
          refute_body(support_message)
        end
      end
    end
  end

  describe "#show" do
    let(:incompatible_message) { "Incompatible Command Schema" }

    context "when visiting offset that does not exist" do
      before { get "consumers/commands/123456" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    %w[
      trace
      quiet
      stop
      quiet_all
      stop_all
    ].each do |command|
      context "when visiting #{command} command" do
        before do
          topics_config.consumers.commands.name = commands_topic
          produce(
            commands_topic,
            Fixtures.consumers_commands_file("consumers/v1.2.0_#{command}.json")
          )
          get "consumers/commands/0"
        end

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          refute_body(pagination)
          refute_body(support_message)
          assert_body("<td>Type</td>")
          assert_body('<code class="json"')
          # quiet_all and stop_all display just stop with a wildcard target
          assert_body("<td>consumers.#{command.split("_").first}</td>")
          refute_body(incompatible_message)
        end
      end

      context "when visiting #{command} command that is not with a compatible schema" do
        before do
          topics_config.consumers.commands.name = commands_topic
          data = Fixtures.consumers_commands_json("consumers/v1.1.0_#{command}")
          data[:schema_version] = "0.0.1"
          produce(commands_topic, data.to_json)
          get "consumers/commands/0"
        end

        it do
          assert(response.ok?)
          assert_body(breadcrumbs)
          refute_body(pagination)
          refute_body(support_message)
          refute_body("<td>Type</td>")
          refute_body('<code class="json"')
          refute_body("<td>#{command}</td>")
          assert_body(incompatible_message)
        end
      end
    end

    context "when visiting trace result" do
      before do
        topics_config.consumers.commands.name = commands_topic
        produce(
          commands_topic,
          Fixtures.consumers_commands_file("consumers/v1.2.0_trace_result.json")
        )
        get "consumers/commands/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        refute_body(incompatible_message)
        assert_body("rb:539:in `rd_kafka_consumer_poll")
        assert_body("Metadata")
        assert_body("trace result")
        assert_body("shinra:397793:6fa3f39acf46")
      end
    end

    context "when visiting trace result that is not with a compatible schema" do
      before do
        topics_config.consumers.commands.name = commands_topic
        data = Fixtures.consumers_commands_json("consumers/v1.1.0_trace_result")
        data[:schema_version] = "0.0.1"
        produce(commands_topic, data.to_json)
        get "consumers/commands/0"
      end

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body(incompatible_message)
      end
    end
  end

  describe "#recent" do
    context "when commands topic does not exist" do
      before do
        topics_config.consumers.commands.name = generate_topic_name

        get "consumers/commands/recent"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when no messages are present" do
      before do
        topics_config.consumers.commands.name = commands_topic
        get "consumers/commands/recent"
      end

      it do
        assert_equal(302, response.status)
        assert_equal("/commands", response.location)
      end
    end

    context "when message exists" do
      before { get "consumers/commands/recent" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body("<td>Type</td>")
        assert_body('<code class="json"')
        assert_body("<td>consumers.")
      end
    end
  end
end
