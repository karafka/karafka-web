# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Helpers
        module Ttls
          # Sum of values added within the ttl, kept as one second buckets, so it does not hold
          # an object per added value
          #
          # @note A bucket expires when its oldest possible value is older than the ttl, so the sum
          #   may miss values added up to one second before the ttl ends
          class Sum
            include ::Karafka::Core::Helpers::Time

            # @param ttl [Integer] milliseconds ttl
            def initialize(ttl)
              @ttl = ttl
              @buckets = []
              @sums = []
            end

            # @param value [Numeric] value to add to the sum
            # @return [Numeric] added value
            def <<(value)
              bucket = (monotonic_now / 1_000).floor

              if @buckets.last == bucket
                @sums[-1] += value
              else
                @buckets << bucket
                @sums << value
              end

              clear

              value
            end

            # @return [Boolean] were there no values added within the ttl
            def empty?
              clear
              @sums.empty?
            end

            # @return [Numeric] sum of values added within the ttl
            def sum
              clear
              @sums.sum
            end

            private

            # Evicts expired buckets
            #
            # @note Buckets are appended in time order, so the expired ones are always a prefix
            def clear
              now = monotonic_now

              while !@buckets.empty? && now - (@buckets.first * 1_000) > @ttl
                @buckets.shift
                @sums.shift
              end
            end
          end
        end
      end
    end
  end
end
