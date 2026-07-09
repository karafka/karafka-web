# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Refreshes the counters that are computed based on incoming reports and not a
              # total sum.
              #
              # For this we use active reports we have in memory. It may not be accurate for the
              # first few seconds but it is much more optimal from performance perspective than
              # computing this fetching all data from Kafka for each view.
              class RefreshCurrentStats < Base
                # Resets and recomputes the `context.state[:stats]` snapshot from
                # `context.active_reports`
                def call
                  stats = context.state[:stats]

                  stats[:busy] = 0
                  stats[:enqueued] = 0
                  stats[:waiting] = 0
                  stats[:workers] = 0
                  stats[:processes] = 0
                  stats[:rss] = 0
                  stats[:listeners] = { active: 0, standby: 0 }
                  stats[:lag_hybrid] = 0
                  stats[:bytes_received] = 0
                  stats[:bytes_sent] = 0
                  utilization = 0

                  context
                    .active_reports
                    .values
                    .reject { |report| report[:process][:status] == "stopped" }
                    .each do |report|
                      report_stats = report[:stats]
                      report_process = report[:process]

                      lags_hybrid = []

                      iterate_partitions(report) do |partition_stats|
                        lag_stored = partition_stats[:lag_stored]
                        lag = partition_stats[:lag]

                        lags_hybrid << (lag_stored.negative? ? lag : lag_stored)
                      end

                      stats[:busy] += report_stats[:busy]
                      stats[:enqueued] += report_stats[:enqueued]
                      stats[:waiting] += report_stats[:waiting] || 0
                      stats[:workers] += report_process[:workers] || 0
                      stats[:bytes_received] += report_process[:bytes_received] || 0
                      stats[:bytes_sent] += report_process[:bytes_sent] || 0
                      stats[:listeners][:active] += report_process[:listeners][:active]
                      stats[:listeners][:standby] += report_process[:listeners][:standby]
                      stats[:processes] += 1
                      stats[:rss] += report_process[:memory_usage]
                      stats[:lag_hybrid] += lags_hybrid.compact.reject(&:negative?).sum
                      utilization += report_stats[:utilization]
                    end

                  stats[:utilization] = stats[:processes].zero? ? 0.0 : utilization / stats[:processes]
                end

                private

                # @param report [Hash]
                # @param block [Proc]
                # @yieldparam partition_stats [Hash] statistics for a single partition
                def iterate_partitions(report, &block)
                  report[:consumer_groups].each_value do |consumer_group|
                    consumer_group[:subscription_groups].each_value do |subscription_group|
                      subscription_group[:topics].each_value do |topic|
                        topic[:partitions].each_value(&block)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
