# frozen_string_literal: true

module Karafka
  module Web
    module Mcp
      # Answers every request with a Pro-only error, as the Web UI does for its Pro pages
      class ProOnlyApp
        class << self
          # @param _env [Hash] Rack env
          # @return [Array] Rack response
          def call(_env)
            [
              402,
              { "content-type" => "text/plain" },
              ["The MCP server is a Karafka Pro feature and requires a Karafka Pro license"]
            ]
          end
        end
      end
    end
  end
end
