# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Helpers
        # Namespace for time sensitive related buffers and operators
        module Ttls
          # Array that allows us to store data points that expire over time automatically.
          class Array
            include ::Karafka::Core::Helpers::Time
            include Enumerable

            # @param ttl [Integer] milliseconds ttl
            def initialize(ttl)
              @ttl = ttl
              @accu = []
            end

            # Iterates over only active elements
            def each
              clear

              @accu.each do |sample|
                yield sample[:value]
              end
            end

            # @param value [Object] adds value to the array
            # @return [Object] added element
            def <<(value)
              @accu << { value: value, added_at: monotonic_now }

              clear

              value
            end

            # @return [Boolean] is the array empty
            def empty?
              clear
              @accu.empty?
            end

            # Samples that are within our TTL time window with the times
            #
            # @return [Hash]
            def samples
              clear
              @accu
            end

            # @return [::Array] pure array version with only active elements
            def to_a
              clear
              super
            end

            private

            # Evicts outdated samples
            def clear
              @accu.delete_if do |sample|
                monotonic_now - sample[:added_at] > @ttl
              end
            end
          end
        end
      end
    end
  end
end
