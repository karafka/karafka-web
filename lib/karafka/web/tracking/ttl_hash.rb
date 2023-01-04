# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Hash that accumulates data that has an expiration date (ttl)
      # Used to keep track of metrics in a window
      class TtlHash < Hash
        # @param ttl [Integer] milliseconds ttl
        def initialize(ttl)
          super() { |k, v| k[v] = TtlArray.new(ttl) }
        end
      end
    end
  end
end
