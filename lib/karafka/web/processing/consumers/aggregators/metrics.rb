# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          # Aggregates metrics for metrics topic. Tracks consumers data and converts it into a
          # state that can then be used to enrich previous time based states to get a time-series
          # values for charts and metrics
          class Metrics
            include ::Karafka::Core::Helpers::Time

            # Current schema version
            # This can be used in the future for detecting incompatible changes and writing
            # migrations
            SCHEMA_VERSION = '1.0.0'

            private_constant :SCHEMA_VERSION

            def initialize
              @active_reports = {}
            end

            # Adds the current report to active reports and removes old once
            #
            # @param report [Hash] single process full report
            def add(report)
              memoize_process_report(report)
              evict_expired_processes
            end

            # Updates the aggregated stats metrics
            #
            # @param stats [Hash] aggregated statistics
            def update_aggregated_stats(stats)
              metrics[:aggregated] = TimeSeriesTracker.new(
                metrics.fetch(:aggregated),
                stats
              ).to_h
            end

            # Converts our current knowledge into a report hash.
            #
            # @note We materialize the consumers groups time series only here and not in real time,
            #   because we materialize it based on the tracked active collective state. Materializing
            #   on each update that would not be dispatched would be pointless.
            #
            # @return [Hash] Statistics hash
            def to_h(*_args)
              metrics[:schema_version] = SCHEMA_VERSION
              metrics[:dispatched_at] = float_now

              metrics[:consumer_groups] = TimeSeriesTracker.new(
                metrics.fetch(:consumer_groups),
                materialize_consumers_groups_current_state
              ).to_h

              metrics
            end

            private

            # @return [Hash] the initial metric taken from Kafka
            def metrics
              @metrics ||= Consumers::Metrics.current!
            end

            # Updates the report for given process in memory
            # @param report [Hash]
            def memoize_process_report(report)
              @active_reports[report[:process][:name]] = report
            end

            # Evicts outdated reports.
            #
            # @onte This eviction differs from the one that we have for the states. For states we do
            #   not evict stopped because we want to report them for a moment. Here we do not care
            #   about what a stopped process was doing and we can also remove it from active reports.
            def evict_expired_processes
              max_ttl = float_now - ::Karafka::Web.config.ttl / 1_000

              @active_reports.delete_if do |_name, report|
                report[:dispatched_at] < max_ttl || report[:process][:status] == 'stopped'
              end
            end

            # Materializes the current state of consumers group data
            #
            # At the moment we report only topics lags but the format we are using supports extending
            # this information in the future if it would be needed.
            #
            # @return [Hash] hash with nested consumers and their topics details structure
            # @note We do **not** report on a per partition basis because it would significantly
            #   increase needed storage.
            def materialize_consumers_groups_current_state
              cgs = {}

              @active_reports.each do |_, details|
                details.fetch(:consumer_groups).each do |group_name, details|
                  details.fetch(:subscription_groups).each do |_sg_name, sg_details|
                    sg_details.fetch(:topics).each do |topic_name, topic_details|
                      partitions_data = topic_details.fetch(:partitions).values

                      lags = partitions_data
                             .map { |p_details| p_details.fetch(:lag) }
                             .reject(&:negative?)

                      lags_stored = partitions_data
                                    .map { |p_details| p_details.fetch(:lag_stored) }
                                    .reject(&:negative?)

                      # If there is no lag that would not be negative, it means we did not mark
                      # any messages as consumed on this topic in any partitons, hence we cannot
                      # compute lag easily
                      # We do not want to initialize any data for this topic, when there is nothing
                      # useful we could present
                      #
                      # In theory lag stored must mean that lag must exist but just to be sure we
                      # check both here
                      next if lags.empty? ||lags_stored.empty?

                      cgs[group_name] ||= {}
                      cgs[group_name][topic_name] = {
                        lag_stored: lags_stored.sum,
                        lag: lags.sum
                      }
                    end
                  end
                end
              end

              cgs
            end
          end
        end
      end
    end
  end
end
