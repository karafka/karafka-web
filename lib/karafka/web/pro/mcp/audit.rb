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
        # Writes one audit record per `tools/call` to the MCP audit topic, so users can review
        # what agents did. Changing tools also get an intent record written before they act
        class Audit
          include ::Karafka::Core::Helpers::Time

          # Version of the audit record format
          SCHEMA_VERSION = "1.0.0"

          # Keys with these in their names hold credentials and are never written
          SECRET_SCOPES = %w[
            sasl
            ssl
          ].freeze

          # Longer strings are cut so a record stays small
          MAX_STRING_SIZE = 1_024

          # Longer arrays are cut so a record stays small
          MAX_ITEMS = 50

          # Longer strings are left out of the result summary
          MAX_SUMMARY_STRING_SIZE = 128

          private_constant :SECRET_SCOPES, :MAX_STRING_SIZE, :MAX_ITEMS, :MAX_SUMMARY_STRING_SIZE

          # @param env [Hash] Rack env of the MCP request
          def initialize(env)
            @env = env
          end

          # Writes the record of a changing tool call before it acts
          #
          # @param call_id [String] id shared by all the records of one call
          # @param tool [String, nil] tool name
          # @param arguments [Object] tool arguments
          # @return [Boolean] true when the record was written with full acks
          def intent(call_id, tool, arguments)
            write(record("intent", call_id, tool, arguments), sync: true)
          end

          # Writes the record with the call outcome
          #
          # @param call_id [String] id shared by all the records of one call
          # @param tool [String, nil] tool name
          # @param arguments [Object] tool arguments
          # @param outcome [String] `ok`, `tool_error`, `exception` or `rejected`
          # @param sync [Boolean] should we wait for the write with full acks
          # @param started_at [Float, nil] monotonic time the tool started at
          # @param error [String, nil] tool error message, rejection reason or exception class
          # @param summary [Hash, nil] short summary of the tool result
          # @return [Boolean] true when the record was written (or handed over when async)
          def result(
            call_id,
            tool,
            arguments,
            outcome:,
            sync:,
            started_at: nil,
            error: nil,
            summary: nil
          )
            payload = record("result", call_id, tool, arguments).merge(
              outcome: outcome,
              error: error,
              duration: started_at ? (monotonic_now - started_at).round(2) : nil,
              summary: summary
            )

            write(payload, sync: sync)
          end

          # @param data [Object] structured content of a tool result
          # @return [Hash, nil] counts of the listed items and short scalar values
          def summarize(data)
            return nil unless data.is_a?(Hash)

            data.each_with_object({}) do |(key, value), summary|
              case value
              when Array
                summary[key] = value.size
              when Numeric, true, false
                summary[key] = value
              when String
                summary[key] = value if value.size <= MAX_SUMMARY_STRING_SIZE
              end
            end
          end

          private

          # @param type [String] record type
          # @param call_id [String]
          # @param tool [String, nil]
          # @param arguments [Object]
          # @return [Hash] fields common to all the records
          def record(type, call_id, tool, arguments)
            {
              schema_version: SCHEMA_VERSION,
              id: SecureRandom.uuid,
              call_id: call_id,
              type: type,
              dispatched_at: float_now,
              tool: tool,
              arguments: sanitize(arguments),
              actor: actor
            }
          end

          # @param payload [Hash]
          # @param sync [Boolean]
          # @return [Boolean] true when written
          def write(payload, sync:)
            message = {
              topic: ::Karafka::Web.config.topics.mcp_audit.name,
              key: payload[:call_id],
              payload: payload.to_json
            }

            if sync
              ::Karafka::Web.producers.fully_acked.produce_sync(**message)
            else
              ::Karafka::Web.producers.default.produce_async(**message)
            end

            true
          rescue => e
            ::Karafka.monitor.instrument(
              "error.occurred",
              error: e,
              caller: self,
              type: "web.mcp.audit.error"
            )

            false
          end

          # @return [Hash] who called, from the configured callable or from the request
          def actor
            @actor ||= ::Karafka::Web.config.mcp.audit.actor&.call(@env) || {
              remote_ip: @env["REMOTE_ADDR"],
              user_agent: @env["HTTP_USER_AGENT"]
            }
          end

          # @param value [Object]
          # @return [Object] value with credentials masked and long values cut
          def sanitize(value)
            case value
            when Hash
              value.to_h do |key, nested|
                if SECRET_SCOPES.any? { |scope| key.to_s.include?(scope) }
                  [key, "***"]
                else
                  [key, sanitize(nested)]
                end
              end
            when Array
              value.first(MAX_ITEMS).map { |item| sanitize(item) }
            when String
              (value.size > MAX_STRING_SIZE) ? "#{value[0, MAX_STRING_SIZE]}..." : value
            else
              value
            end
          end
        end
      end
    end
  end
end
