# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Helpers
        module Ttls
          # Hash that accumulates data that has an expiration date (ttl)
          # Used to keep track of metrics in a window
          class Hash < Hash
            # @param ttl [Integer] milliseconds ttl
            def initialize(ttl)
              super() { |k, v| k[v] = Ttls::Array.new(ttl) }
            end

            # Takes a block where we provide a hash select filtering to select keys we are
            # interested in using for aggregated stats. Once filtered, builds a Stats object out
            # of the candidates
            #
            # @param block [Proc] block for selection of elements for stats
            # @yieldparam [String] key
            # @yieldparam [Ttls::Array] samples
            # @return [Stats]
            def stats_from(&block)
              Stats.new(
                select(&block)
              )
            end
          end
        end
      end
    end
  end
end
