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
            # auth). When not set or when it returns nil, the remote IP and User-Agent are used
            setting :actor, default: nil

            # Refuse read-only tools results when their audit record cannot be written. Changing
            # tools always refuse to act when their intent cannot be written
            setting :fail_closed_reads, default: false
          end

          # Changing tools agents may list and call: an array of their names or `:all`. None by
          # default. Each one still passes the same Web UI features and policies as in the UI
          setting :changing_tools, default: []

          # Path the Web UI is mounted at in the host app (for example "/karafka"). The requests
          # policy checks each changing tool call as a request to the matching Web UI action under
          # this path, so policies that read `SCRIPT_NAME`, `path` or `REQUEST_URI` see the same
          # path as for the Web UI
          setting :web_ui_path, default: ""

          configure
        end
      end
    end
  end
end
