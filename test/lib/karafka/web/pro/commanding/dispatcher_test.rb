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
  before { Karafka::Web.config.topics.consumers.commands.name = commands_topic }

  let(:commands_topic) { generate_topic_name }

  before { Karafka::Web.producer.stubs(:produce_async) }

  describe ".request" do
    let(:command_name) { "quiet" }

    context "without matchers" do
      it "dispatches a request message without key (filtering via matchers)" do
        Karafka::Web.producer.expects(:produce_async).with( has_entries( topic: commands_topic, partition: 0 ) )
        described_class.request(command_name)

      end
    end

    context "with process_id in matchers" do
      let(:process_id) { "process123" }

      it "dispatches request with matchers for filtering" do
        Karafka::Web.producer.expects(:produce_async).with( has_entries( topic: commands_topic, partition: 0 ) )
        described_class.request(command_name, {}, matchers: { process_id: process_id })

      end
    end
  end

  describe ".result" do
    let(:process_id) { "process123" }
    let(:command_name) { "pause" }
    let(:result) { { success: true } }

    it "dispatches a result message with the correct structure" do
      Karafka::Web.producer.expects(:produce_async).with( has_entries( topic: commands_topic, key: process_id, partition: 0 ) )
      described_class.result(command_name, process_id, result)

    end
  end
end
