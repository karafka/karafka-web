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
              @ttl = ttl
              super() { |k, v| k[v] = Ttls::Array.new(@ttl) }
            end

            # Takes a block where we provide a hash select filtering to select keys we are
            # interested in using for aggregated stats. Once filtered, builds a Stats object out
            # of the candidates
            #
            # @yieldparam [String] key
            # @yieldparam [Ttls::Array] samples
            # @return [Stats]
            def stats_from(&)
              Stats.new(
                select(&)
              )
            end

            # @return [String] thread-safe inspect of the ttls hash
            def inspect
              "#<#{self.class.name}:#{format("%#x", object_id)} size=#{size} ttl=#{@ttl}ms>"
            end
          end
        end
      end
    end
  end
end
