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
  let(:topic_name) { "orders" }
  let(:property_name) { "max.message.bytes" }
  let(:data) { { property_value: "42" } }
  let(:result) { described_class.call(topic_name, property_name, data) }

  it "returns an admin configs resource for the topic" do
    assert_instance_of(Karafka::Admin::Configs::Resource, result)
    assert_equal(topic_name, result.name)
  end

  it "sets the requested property on the resource" do
    resource = mock

    Karafka::Admin::Configs::Resource
      .expects(:new)
      .with(type: :topic, name: topic_name)
      .returns(resource)

    resource.expects(:set).with(property_name, "42")

    assert_equal(resource, described_class.call(topic_name, property_name, data))
  end
end
