# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          # Aggregates metrics for metrics topic. Tracks consumers data and converts it into a
          # state that can then be used to enrich previous time based states to get a time-series
          # values for charts and metrics
          class Metrics < Base
            # Current schema version
            # This can be used in the future for detecting incompatible changes and writing
            # migrations
            SCHEMA_VERSION = '1.0.0'

            def initialize
              super
              @aggregated_tracker = TimeSeriesTracker.new(metrics.fetch(:aggregated))
              @consumer_groups_tracker = TimeSeriesTracker.new(metrics.fetch(:consumer_groups))
            end

            # Adds the current report to active reports and removes old once
            #
            # @param report [Hash] single process full report
            def add_report(report)
              add(report)
              evict_expired_processes
              add_consumers_groups_metrics
            end

            # Updates the aggregated stats metrics
            #
            # @param stats [Hash] aggregated statistics
            def add_stats(stats)
              metrics[:aggregated] = @aggregated_tracker.add(
                stats,
                @aggregated_from
              )
            end

            # Converts our current knowledge into a report hash.
            #
            # @return [Hash] Statistics hash
            #
            # @note We materialize the consumers groups time series only here and not in real time,
            #   because we materialize it based on the tracked active collective state. Materializing
            #   on each update that would not be dispatched would be pointless.
            def to_h
              metrics[:schema_version] = SCHEMA_VERSION
              metrics[:dispatched_at] = float_now
              metrics[:aggregated] = @aggregated_tracker.to_h
              metrics[:consumer_groups] = @consumer_groups_tracker.to_h

              metrics
            end

            private

            # @return [Hash] the initial metric taken from Kafka
            def metrics
              @metrics ||= Consumers::Metrics.current!
            end

            # Evicts outdated reports.
            #
            # @note This eviction differs from the one that we have for the states. For states we
            #   do not evict stopped because we want to report them for a moment. Here we do not
            #   care about what a stopped process was doing and we can also remove it from active
            #   reports.
            def evict_expired_processes
              max_ttl = @aggregated_from - ::Karafka::Web.config.ttl / 1_000

              @active_reports.delete_if do |_name, report|
                report[:dispatched_at] < max_ttl || report[:process][:status] == 'stopped'
              end
            end

            # Materialize and add consumers groups states into the tracker
            def add_consumers_groups_metrics
              @consumer_groups_tracker.add(
                materialize_consumers_groups_current_state,
                @aggregated_from
              )
            end

            # Materializes the current state of consumers group data
            #
            # At the moment we report only topics lags but the format we are using supports
            # extending this information in the future if it would be needed.
            #
            # @return [Hash] hash with nested consumers and their topics details structure
            # @note We do **not** report on a per partition basis because it would significantly
            #   increase needed storage.
            def materialize_consumers_groups_current_state
              cgs = {}

              @active_reports.each do |_, details|
                details.fetch(:consumer_groups).each do |group_name, group_details|
                  group_details.fetch(:subscription_groups).each do |_sg_name, sg_details|
                    sg_details.fetch(:topics).each do |topic_name, topic_details|
                      partitions_data = topic_details.fetch(:partitions).values

                      lags = partitions_data
                             .map { |p_details| p_details[:lag] || 0 }
                             .reject(&:negative?)

                      lags_stored = partitions_data
                                    .map { |p_details| p_details.fetch(:lag_stored) }
                                    .reject(&:negative?)

                      offsets_hi = partitions_data
                                   .map { |p_details| p_details.fetch(:hi_offset) }
                                   .reject(&:negative?)

                      # If there is no lag that would not be negative, it means we did not mark
                      # any messages as consumed on this topic in any partitions, hence we cannot
                      # compute lag easily
                      # We do not want to initialize any data for this topic, when there is nothing
                      # useful we could present
                      #
                      # In theory lag stored must mean that lag must exist but just to be sure we
                      # check both here
                      next if lags.empty? || lags_stored.empty?

                      cgs[group_name] ||= {}
                      cgs[group_name][topic_name] = {
                        lag_stored: lags_stored.sum,
                        lag: lags.sum,
                        pace: offsets_hi.sum
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
