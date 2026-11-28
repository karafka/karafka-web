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

module Karafka
  module Web
    module Pro
      module Mcp
        # Pro MCP server settings
        class Config
          extend ::Karafka::Core::Configurable

          # Audit log of the tools calls, written to the `topics.mcp_audit` topic
          setting :audit do
            # Callable that gets the Rack env and returns who called (e.g. from the host app
            # auth). The actor identifies the caller only when the host app auth supplies it.
            # When not set or when it returns nil, the remote IP and User-Agent are used. They
            # are request details, not an identity
            setting :actor, default: nil

            # Refuse read-only tools results when their audit record cannot be written. Changing
            # tools always refuse to act when their intent cannot be written
            setting :fail_closed_reads, default: false
          end

          # Tools that read messages of topics and dead letter queues. Off by default, apart from
          # the other read-only tools, because payloads can hold personal data
          setting :messages do
            # Should the messages tools be listed and callable
            setting :active, default: false
          end

          configure
        end
      end
    end
  end
end
