# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects network throughput metrics (bytes received/sent per second)
            class Network < Base
              # @param windows [Helpers::Ttls::Windows] time windows for aggregating metrics
              def initialize(windows)
                super()
                @windows = windows
              end

              # @return [Integer] number of bytes received per second out of a one minute time
              #   window by all the consumers
              # @note We use one minute window to compensate for cases where metrics would be
              #   reported or recorded faster or slower. This normalizes data
              def bytes_received
                windows
                  .m1
                  .stats_from { |k, _v| k.end_with?("rxbytes") }
                  .rps
                  .round
              end

              # @return [Integer] number of bytes sent per second out of a one minute time window by
              #   all the consumers
              def bytes_sent
                windows
                  .m1
                  .stats_from { |k, _v| k.end_with?("txbytes") }
                  .rps
                  .round
              end

              private

              attr_reader :windows
            end
          end
        end
      end
    end
  end
end
