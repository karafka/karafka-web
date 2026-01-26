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

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:commands_topic) { create_topic }
  let(:no_commands) { "No commands found." }

  describe "#index" do
    context "when commands topic does not exist" do
      before do
        topics_config.consumers.commands.name = generate_topic_name

        get "consumers/commands"
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when there are no commands" do
      before do
        topics_config.consumers.commands.name = commands_topic

        get "consumers/commands"
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_commands)
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
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_commands)
        expect(body).not_to include(pagination)
        expect(body).not_to include('<span class="badge badge-primary">')
        expect(body).not_to include("/consumers/shinra:1404842:f66b40c75f92/subscriptions")
        expect(body).not_to include("/commands/0")
        expect(body).to include(breadcrumbs)
        expect(body).to include("Incompatible command schema.")
      end
    end

    context "when there are active commands" do
      before { get "consumers/commands" }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_commands)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('<span class="badge badge-primary">')
        expect(body).to include("command")
        expect(body).to include("quiet")
        expect(body).to include("process_id:")
        expect(body).to include("/commands/0")
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
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include("commands/99")
          expect(body).to include("trace")
          expect(body).to include("quiet")
          expect(body).to include("stop")
        end
      end

      context "when we visit second page" do
        before { get "consumers/commands/overview?offset=52" }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include("commands/53")
          expect(body).not_to include("commands/99")
          expect(body).to include("trace")
          expect(body).to include("quiet")
          expect(body).to include("stop")
          expect(body).not_to include(support_message)
        end
      end

      context "when we go beyond available offsets" do
        before { get "consumers/commands/overview?offset=200" }

        it do
          expect(response).to be_ok
          expect(body).not_to include(pagination)
          expect(body).to include(no_commands)
          expect(body).not_to include(support_message)
        end
      end
    end
  end

  describe "#show" do
    let(:incompatible_message) { "Incompatible Command Schema" }

    context "when visiting offset that does not exist" do
      before { get "consumers/commands/123456" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
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
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include("<td>Type</td>")
          expect(body).to include('<code class="json"')
          # quiet_all and stop_all display just stop with a wildcard target
          expect(body).to include("<td>consumers.#{command.split("_").first}</td>")
          expect(body).not_to include(incompatible_message)
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
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).not_to include("<td>Type</td>")
          expect(body).not_to include('<code class="json"')
          expect(body).not_to include("<td>#{command}</td>")
          expect(body).to include(incompatible_message)
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
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include(incompatible_message)
        expect(body).to include("rb:539:in `rd_kafka_consumer_poll")
        expect(body).to include("Metadata")
        expect(body).to include("trace result")
        expect(body).to include("shinra:397793:6fa3f39acf46")
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
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(incompatible_message)
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
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when no messages are present" do
      before do
        topics_config.consumers.commands.name = commands_topic
        get "consumers/commands/recent"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/commands")
      end
    end

    context "when message exists" do
      before { get "consumers/commands/recent" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include("<td>Type</td>")
        expect(body).to include('<code class="json"')
        expect(body).to include("<td>consumers.")
      end
    end
  end
end
