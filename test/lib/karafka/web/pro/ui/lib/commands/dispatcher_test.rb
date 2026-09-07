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
  let(:command) do
    {
      name: "partitions.seek",
      payload: { consumer_group_id: "cg", topic: "t", partition_id: 0, offset: 5 },
      matchers: { consumer_group_id: "cg", topic: "t", partition_id: 0 }
    }
  end

  it "requests the command via the commanding dispatcher and returns its handle" do
    Karafka::Web::Pro::Commanding::Dispatcher
      .expects(:request)
      .with(command[:name], command[:payload], matchers: command[:matchers])
      .returns(:handle)

    assert_equal(:handle, described_class.new(command).call)
  end
end
