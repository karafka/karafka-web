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
            # This is used for detecting incompatible changes and writing migrations
            SCHEMA_VERSION = '1.3.0'

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

              @active_reports.delete_if do |_id, report|
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
            # @return [Hash] hash with nested consumers and their topics details structure
            # @note We do **not** report on a per partition basis because it would significantly
            #   increase needed storage.
            def materialize_consumers_groups_current_state
              cgs = {}

              iterate_partitions_data do |group_name, topic_name, partitions_data|
                lags_hybrid = partitions_data
                              .map do |p_details|
                                lag_stored = p_details.fetch(:lag_stored, -1)
                                lag_stored.negative? ? p_details.fetch(:lag, -1) : lag_stored
                              end
                              .reject(&:negative?)

                offsets_hi = partitions_data
                             .map { |p_details| p_details.fetch(:hi_offset, -1) }
                             .reject(&:negative?)

                # Last stable offsets freeze durations - we pick the max freeze to indicate
                # the longest open transaction that potentially may be hanging
                # We select only those partitions for which LSO != HO as in any other case this
                # just means we've reached the end of data and ls may freeze because there is no
                # more data flowing. Such cases should not be reported as ls offset freezes because
                # there is no more data to be processed and can grow until more data is present
                # this does not indicate "bad" freezing that we are interested in
                ls_offsets_fds = partitions_data.map do |p_details|
                  next if p_details.fetch(:ls_offset, 0) == p_details.fetch(:hi_offset, 0)

                  ls_offset_fd = p_details.fetch(:ls_offset_fd, 0)

                  ls_offset_fd.negative? ? nil : ls_offset_fd
                end

                cgs[group_name] ||= {}
                cgs[group_name][topic_name] = {
                  lag_hybrid: lags_hybrid.sum,
                  pace: offsets_hi.sum,
                  # Take max last stable offset duration without any change. This can
                  # indicate a hanging transaction, because the offset will not move forward
                  # and will stay with a growing freeze duration when stuck
                  ls_offset_fd: ls_offsets_fds.compact.max || 0
                }
              end

              cgs
            end

            # Converts our reports data into an iterator per partition
            # Compensates for a case where same partition data would be available for a short
            # period of time in multiple processes reports due to rebalances.
            def iterate_partitions_data
              cgs_topics = Hash.new { |h, v| h[v] = Hash.new { |h2, v2| h2[v2] = {} } }

              # We need to sort them in case we have same reports containing data about same
              # topics partitions. Mostly during shutdowns and rebalances
              @active_reports
                .values
                .sort_by { |report| report.fetch(:dispatched_at) }
                .map { |details| details.fetch(:consumer_groups) }
                .each do |consumer_groups|
                  consumer_groups.each do |group_name, group_details|
                    group_details.fetch(:subscription_groups).each_value do |sg_details|
                      sg_details.fetch(:topics).each do |topic_name, topic_details|
                        topic_details.fetch(:partitions).each do |partition_id, partition_data|
                          cgs_topics[group_name][topic_name][partition_id] = partition_data
                        end
                      end
                    end
                  end
                end

              cgs_topics.each do |group_name, topics_data|
                topics_data.each do |topic_name, partitions_data|
                  yield(group_name, topic_name, partitions_data.values)
                end
              end
            end
          end
        end
      end
    end
  end
end
