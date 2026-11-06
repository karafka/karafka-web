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
      # Read-only Model Context Protocol (MCP) server for AI agents. It speaks MCP over plain
      # HTTP request/response (no SSE, no sessions), so it needs no gems beyond Roda and stdlib
      module Mcp
        # Rack app with the MCP endpoint. Mounting it is the opt-in, for example:
        #
        #   mount Karafka::Web::Pro::Mcp::App, at: "/karafka/mcp"
        #
        # Like the Web UI, it has no authentication of its own: the host app protects the mount.
        # It does not inherit from the Web UI base app, so it has no sessions and no browser CSRF
        # hook, which MCP clients could not satisfy.
        class App < Roda
          plugin :hooks

          # Paths under which the endpoint answers, relative to the mount point
          ENDPOINT_PATHS = ["", "/"].freeze

          private_constant :ENDPOINT_PATHS

          before do
            # If policies extension is not loaded, allow as this is the default
            next if !Web.config.ui.respond_to?(:policies) ||
              Web.config.ui.policies.requests.allow?(env)

            request.halt(Responses.http_error(403, "Forbidden"))
          end

          route do |r|
            r.halt(Responses.http_error(404, "Not Found")) unless ENDPOINT_PATHS.include?(r.path_info)
            r.halt(Responses.http_error(403, "Invalid Origin")) unless valid_origin?
            r.halt(Responses.method_not_allowed) unless r.post?
            r.halt(Responses.http_error(415, "Unsupported Media Type")) unless json_content?

            version = env["HTTP_MCP_PROTOCOL_VERSION"]

            if version && !Server::PROTOCOL_VERSIONS.include?(version)
              r.halt(Responses.http_error(400, "Unsupported MCP-Protocol-Version"))
            end

            r.halt(Server.new.call(r.body.read))
          end

          private

          # MCP requires servers to reject requests whose `Origin` (sent by browsers) is not ours,
          # which protects against DNS rebinding. Clients other than browsers send no `Origin`.
          #
          # @return [Boolean]
          def valid_origin?
            origin = env["HTTP_ORIGIN"]

            return true if origin.nil?

            origin == request.base_url
          end

          # @return [Boolean] true if the request body is declared as JSON
          def json_content?
            request.media_type == "application/json"
          end
        end
      end
    end
  end
end
