# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Namespace for data aggregators that track changes based on the incoming reports and
        # aggregate metrics over time
        module Aggregators
          # Base for all the consumer related aggregators that operate on processes reports
          #
          # @note It is important to understand, that we operate here on a moment in time and this
          #   moment may not mean "current" now. There might have been a lag and we may be catching
          #   up on older states. This is why we use `@aggregated_from` time instead of the real
          #   now. In case of a lag, we want to aggregate and catch up with data, without
          #   assigning it to the time of processing but aligning it with the time from which the
          #   given reports came. This allows us to compensate for the potential lag related to
          #   rebalances, downtimes, failures, etc.
          class Base
            include ::Karafka::Core::Helpers::Time

            def initialize
              @active_reports = {}
            end

            # Adds report to the internal active reports hash and updates the aggregation time
            # for internal time reference usage
            # @param report [Hash] incoming process state report
            def add(report)
              memoize_process_report(report)
              update_aggregated_from
            end

            private

            # Updates the report for given process in memory
            # @param report [Hash]
            def memoize_process_report(report)
              @active_reports[report[:process][:id]] = report
            end

            # Updates the time of the aggregation
            #
            # @return [Float] time of the aggregation
            #
            # @note Since this runs before eviction because of age, we always assume there is at
            #   least one report from which we can take the dispatch time
            def update_aggregated_from
              @aggregated_from = @active_reports.values.map { |report| report[:dispatched_at] }.max
            end
          end
        end
      end
    end
  end
end
