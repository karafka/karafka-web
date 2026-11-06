# frozen_string_literal: true

module Karafka
  module Web
    # Namespace for the MCP (Model Context Protocol) server, which is a Pro feature
    module Mcp
      # Proxy App to mount the MCP server. Without a Pro license it refuses every request with a
      # Pro-only error, as the Web UI does for its Pro pages
      class App
        # Answer when there is no Pro license
        PRO_ONLY = [
          402,
          { "content-type" => "text/plain" },
          ["The MCP server is a Karafka Pro feature and requires a Karafka Pro license"]
        ].freeze

        private_constant :PRO_ONLY

        class << self
          # @param env [Hash] Rack env
          # @return [Array] Rack response
          def call(env)
            return Pro::Mcp::App.call(env) if ::Karafka.pro?

            status, headers, body = PRO_ONLY

            [status, headers.dup, body.dup]
          end
        end
      end
    end
  end
end
