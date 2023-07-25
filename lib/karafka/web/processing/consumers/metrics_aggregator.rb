# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Aggregates metrics for metrics topic. Tracks consumers data and converts it into a
        # state that can then be used to enrich previous time based states to get a time-series
        # values for charts and metrics
        class MetricsAggregator
          include ::Karafka::Core::Helpers::Time

          # Current schema version
          # This can be used in the future for detecting incompatible changes and writing
          # migrations
          SCHEMA_VERSION = '1.0.0'

          private_constant :SCHEMA_VERSION

          def initialize
            @active_reports = {}
          end

          # @param stats [Hash] aggregated statistics
          def update_aggregated_stats(stats)
            metrics[:aggregated] = TimeSeriesTracker.new(
              metrics.fetch(:aggregated),
              stats
            ).to_h
          end

          def add(report)
            memoize_process_report(report)
            evict_expired_processes
          end

          def to_json(*_args)
            metrics[:schema_version] = SCHEMA_VERSION
            metrics[:dispatched_at] = float_now

            cg_metrics = materialize_consumers_groups_current_state

            metrics[:consumer_groups] = TimeSeriesTracker.new(
              metrics.fetch(:consumer_groups),
              cg_metrics
            ).to_h

            metrics.to_json
          end

          private

          def metrics
            @metrics ||= Metrics.current!
          end

          # Updates the report for given process in memory
          # @param report [Hash]
          def memoize_process_report(report)
            @active_reports[report[:process][:name]] = report
          end

          def evict_expired_processes
            max_ttl = float_now - ::Karafka::Web.config.ttl / 1_000

            @active_reports.delete_if do |_name, report|
              report[:dispatched_at] < max_ttl || report[:process][:status] == 'stopped'
            end
          end

          def materialize_consumers_groups_current_state
            cgs = {}

            @active_reports.each do |_, details|
              details[:consumer_groups].each do |group_name, details|
                details[:subscription_groups].each do |sg_name, sg_details|
                  sg_details[:topics].each do |topic_name, topic_details|
                    lags_stored = []

                    topic_details[:partitions].each do |_partition_id, details|
                      lags_stored << details.fetch(:lag_stored)
                    end

                    lags_stored.delete_if(&:negative?)

                    next if lags_stored.empty?

                    cgs[group_name] ||= {}
                    cgs[group_name][topic_name] = {
                      lags_stored: lags_stored.sum
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
