# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Helpers
        module Ttls
          # Object that simplifies computing aggregated statistics out of ttl data
          # For TTL based operations we may collect samples from multiple consumers/producers etc
          # but in the end we are interested in the collective result of the whole process.
          #
          # For example when we talk about data received from Kafka, we want to materialize total
          # number of bytes and not bytes per given client connection. This layer simplifies this
          # by doing necessary aggregations and providing the final results
          class Stats
            # @param ttls_hash [Ttls::Hash, Hash] hash with window based samples
            def initialize(ttls_hash)
              @data = ttls_hash
                      .values
                      .map(&:samples)
                      .map(&:to_a)
                      .delete_if { |samples| samples.size < 2 }
                      .map { |samples| samples.map(&:values) }
            end

            # Computes the rate out of the samples provided on a per second basis. The samples need
            #   to come from the window aggregations
            #
            # @return [Float] per second rate value
            def rps
              sub_results = @data.map do |samples|
                oldest = samples.first
                newest = samples.last

                value = oldest[0] - newest[0]
                # Convert to seconds as we want to have it in a 1 sec pace
                time = (oldest[1] - newest[1]) / 1_000

                value / time.to_f
              end

              sub_results.flatten.sum
            end
          end
        end
      end
    end
  end
end
