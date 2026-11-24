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
  let(:model) { described_class }

  let(:topic) { create_topic }
  let(:not_found_error) { Karafka::Web::Errors::Ui::NotFoundError }
  let(:non_existing_topic) { generate_topic_name }

  before { topic }

  it { assert_includes(model.all.map(&:topic_name), topic) }
  it { refute_includes(model.all.map(&:topic_name), non_existing_topic) }
  it { assert_raises(not_found_error) { model.find(non_existing_topic) } }
  it { assert_equal(topic, model.find(topic).topic_name) }
  it { assert_equal(1, model.partitions_count(topic)) }

  context "when the topic name is not a valid Kafka topic name" do
    before { Karafka::Admin.expects(:topic_info).never }

    it { assert_raises(not_found_error) { model.find("a" * 250) } }
    it { assert_raises(not_found_error) { model.find("a" * 513) } }
    it { assert_raises(not_found_error) { model.find("..") } }
  end
end
