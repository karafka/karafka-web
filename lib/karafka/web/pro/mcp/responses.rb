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
        # Builds the Rack responses of the MCP endpoint
        module Responses
          # Headers of each JSON response
          JSON_HEADERS = {
            "content-type" => "application/json",
            "cache-control" => "no-store"
          }.freeze

          private_constant :JSON_HEADERS

          class << self
            # @param payload [Hash] JSON-RPC response
            # @return [Array] Rack response
            def json(payload)
              [200, JSON_HEADERS.dup, [payload.to_json]]
            end

            # @return [Array] Rack response for notifications and responses sent by the client
            def accepted
              [202, {}, []]
            end

            # @return [Array] Rack response for anything other than POST. We do not offer an SSE
            #   stream, so GET is refused as the MCP spec allows
            def method_not_allowed
              [405, { "allow" => "POST", "content-type" => "text/plain" }, ["Method Not Allowed"]]
            end

            # @param status [Integer] HTTP status
            # @param message [String] plain text body
            # @return [Array] Rack response
            def http_error(status, message)
              [status, { "content-type" => "text/plain" }, [message]]
            end
          end
        end
      end
    end
  end
end
