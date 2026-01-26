# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if there is significant lag in the reporting of aggregated data.
            #
            # If there's a large gap between when data is reported and when it's
            # materialized, the Web UI will show stale information. This often
            # indicates over-saturation on the consumer that materializes states.
            #
            # The maximum acceptable lag is twice the tracking interval.
            #
            # @note Since both states and metrics are reported together, checking
            #   one of them is sufficient.
            class MaterializingLag < Base
              depends_on :live_reporting

              class << self
                # @return [Hash] details with zero lag for halted state
                def halted_details
                  max_lag = (Web.config.tracking.interval * 2) / 1_000
                  { lag: 0, max_lag: max_lag }
                end
              end

              # Executes the materializing lag check.
              #
              # Compares the current state's dispatch time with the current time.
              #
              # @return [Status::Step] success if lag is acceptable, failure if too high
              def call
                max_lag = (Web.config.tracking.interval * 2) / 1_000
                lag = Time.now.to_f - context.current_state.dispatched_at

                status = (lag > max_lag) ? :failure : :success

                step(status, { lag: lag, max_lag: max_lag })
              end
            end
          end
        end
      end
    end
  end
end
