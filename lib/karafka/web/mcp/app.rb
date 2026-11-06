# frozen_string_literal: true

module Karafka
  module Web
    # Namespace for the MCP (Model Context Protocol) server, which is a Pro feature
    module Mcp
      # Proxy App that selects either the Pro MCP server or the app that refuses requests without
      # a Pro license
      class App
        class << self
          # @param env [Hash] Rack env
          def call(env, &)
            engine.call(env, &)
          end

          # @return [Class] Pro MCP server or the Pro-only app
          def engine
            ::Karafka.pro? ? Pro::Mcp::App : ProOnlyApp
          end
        end
      end
    end
  end
end
