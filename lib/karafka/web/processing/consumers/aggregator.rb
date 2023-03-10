# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Namespace for consumer sub-components
      module Consumers
        # Aggregator that tracks consumers processes states, aggregates the metrics and converts
        # data points into a materialized current state.
        class Aggregator
          include ::Karafka::Core::Helpers::Time

          def initialize
            # We keep whole reports for computation of active, current counters
            @active_reports = {}
          end

          # Uses provided process state report to update the current materialized state
          # @param report [Hash] consumer process state report
          # @param offset [Integer] offset of the message with the state report. This offset is
          #   needed as we need to be able to get all the consumers reports from a given offset.
          def add(report, offset)
            memoize_process_report(report)
            increment_total_counters(report)
            update_process_state(report, offset)
            # We always evict after counters updates because we want to use expired (stopped)
            # data for counters as it was valid previously. This can happen only when web consumer
            # had a lag and is catching up.
            evict_expired_processes
            # We could calculate this on a per request basis but this would require fetching all
            # the active processes for each view and we do not want that for performance reasons
            refresh_current_stats
          end

          # @param _args [Object] extra parsing arguments (not used)
          # @return [String] json representation of the current processes state
          def to_json(*_args)
            state.to_json
          end

          private

          # @return [Hash] hash with current state from Kafka or an empty new initial state
          def state
            @state ||= State.current
          end

          # Updates the report for given process in memory
          # @param report [Hash]
          def memoize_process_report(report)
            @active_reports[report[:process][:name]] = report
          end

          # Increments the total counters based on the provided report
          # @param report [Hash]
          def increment_total_counters(report)
            report[:stats][:total].each do |key, value|
              state[:stats][key] ||= 0
              state[:stats][key] += value
            end
          end

          # Registers or updates the given process state based on the report
          #
          # @param report [Hash]
          # @param offset [Integer]
          def update_process_state(report, offset)
            process_name = report[:process][:name]

            state[:processes][process_name] = {
              dispatched_at: report[:dispatched_at],
              offset: offset
            }
          end

          # Evicts expired processes from the current state
          # We consider processes dead if they do not report often enough
          # @note We do not evict based on states (stopped), because we want to report the
          #   stopped processes for extra time within the ttl limitations. This makes tracking of
          #   things from UX perspective nicer.
          def evict_expired_processes
            max_ttl = float_now - ::Karafka::Web.config.ttl / 1_000

            state[:processes].delete_if do |_name, details|
              details[:dispatched_at] < max_ttl
            end

            @active_reports.delete_if do |_name, details|
              details[:dispatched_at] < max_ttl
            end
          end

          # Refreshes the counters that are computed based on incoming reports and not a total sum.
          # For this we use active reports we have in memory. It may not be accurate for the first
          # few seconds but it is much more optimal from performance perspective than computing
          # this fetching all data from Kafka for each view.
          def refresh_current_stats
            stats = state[:stats]

            stats[:busy] = 0
            stats[:enqueued] = 0
            stats[:threads_count] = 0
            stats[:processes] = 0
            stats[:rss] = 0
            stats[:listeners_count] = 0
            utilization = 0

            @active_reports
              .values
              .reject { |report| report[:process][:status] == 'stopped' }
              .each do |report|
                report_stats = report[:stats]
                report_process = report[:process]

                stats[:busy] += report_stats[:busy]
                stats[:enqueued] += report_stats[:enqueued]
                stats[:threads_count] += report_process[:concurrency]
                stats[:processes] += 1
                stats[:rss] += report_process[:memory_usage]
                stats[:listeners_count] += report_process[:listeners]
                utilization += report_stats[:utilization]
              end

            stats[:utilization] = utilization / (stats[:processes] + 0.0001)
          end
        end
      end
    end
  end
end
