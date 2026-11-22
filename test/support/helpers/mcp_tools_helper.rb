# frozen_string_literal: true

# Shared setup of the MCP tools tests: a server with an audit log, JSON-RPC calls to it and the
# records of its audit topic. Each test sets `arguments` and points the audit topic at
# `audit_topic` in its `before`
module McpToolsHelper
  class << self
    # @param base [Class] spec class including the helper
    def included(base)
      base.class_eval do
        let(:server) { Karafka::Web::Pro::Mcp::Server.new(Karafka::Web::Pro::Mcp::Audit.new({})) }
        let(:audit_topic) { create_topic }
        let(:payload) { rpc("tools/call", { name: described_class.name, arguments: arguments }) }
        let(:result) { payload.fetch("result") }
        let(:rpc_error) { payload.fetch("error") }
        let(:listed) { rpc("tools/list").dig("result", "tools").map { |tool| tool["name"] } }
        let(:failing) { stub }
        let(:records) do
          Karafka.producer.client.flush

          Karafka::Admin
            .read_topic(audit_topic, 0, 100)
            .map { |message| JSON.parse(message.raw_payload) }
        end
      end
    end
  end

  # @param rpc_method [String] JSON-RPC method
  # @param params [Hash, nil] JSON-RPC params
  # @return [Hash] parsed JSON-RPC response
  def rpc(rpc_method, params = nil)
    request = { jsonrpc: "2.0", id: 1, method: rpc_method }
    request[:params] = params if params

    JSON.parse(server.call(request.to_json)[2].join)
  end
end
