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
  let(:detector) { described_class.new }
  let(:matched_topic) { create_topic(topic_name: "it-pattern-#{SecureRandom.uuid}") }
  let(:share_topic) { create_topic }
  let(:group_id) { "it-patterns-#{SecureRandom.uuid}" }
  let(:routed_names) { Karafka::App.routes.consumer_groups.flat_map { |cg| cg.topics.to_a }.map(&:name) }

  before do
    matched_topic
    share_name = share_topic
    group = group_id

    draw_routes do
      consumer_group group do
        pattern(/it-pattern-/) do
          consumer Karafka::BaseConsumer
        end
      end

      share_group "it-share-#{SecureRandom.uuid}" do
        topic share_name do
          consumer Karafka::ShareConsumer
        end
      end
    end
  end

  it "expands the consumer group patterns when the routing has a share group" do
    detector.call

    assert_includes(routed_names, matched_topic)
  end
end
