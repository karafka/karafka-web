# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Refreshes `context.state[:paused_partitions_lag]` with fresh cluster-side lag
              # for partitions that have been reported as paused for at least
              # `min_pause_duration`, throttled to run at most once every `refresh_interval`.
              #
              # A paused partition stops being actively fetched, so its self-reported
              # `lag`/`lag_stored` freeze at pause time while the real lag keeps growing. We
              # compensate by asking the cluster directly for a fresh high watermark and
              # combining it with the partition's own still-accurate self-reported
              # `committed_offset`/`stored_offset` (these do not go stale while paused - the
              # consumer genuinely has not processed anything new).
              #
              # @note We use `context.aggregated_from` (report time) rather than wall-clock time
              #   so this stays consistent when catching up on a backlog of older reports.
              class RefreshPausedPartitionsLag < Base
                include PartitionIterator

                def call
                  settings = ::Karafka::Web.config.processing.paused_partitions_lag
                  refreshed_at = context.paused_partitions_lag_refreshed_at

                  if refreshed_at &&
                      (context.aggregated_from - refreshed_at) <
                          (settings.refresh_interval / 1_000.0)
                    return
                  end

                  context.paused_partitions_lag_refreshed_at = context.aggregated_from

                  eligible = eligible_paused_partitions(settings.min_pause_duration / 1_000.0)

                  if eligible.empty?
                    context.state[:paused_partitions_lag] = {}
                    return
                  end

                  fresh_offsets = fetch_fresh_watermarks(eligible, settings.query_timeout)

                  # Graceful degradation: on any admin failure, leave the previous
                  # state[:paused_partitions_lag] untouched rather than wiping it out - a
                  # stale-but-recent correction is still better than none.
                  return unless fresh_offsets

                  context.state[:paused_partitions_lag] = build_paused_partitions_lag(
                    eligible, fresh_offsets
                  )
                end

                private

                # @param min_pause_duration [Float] minimum time (in seconds) a partition must
                #   have been continuously paused before it is eligible for a cluster-side lag
                #   refresh
                # @return [Array<Hash>] one entry per eligible partition: `{ cg_id:, topic:,
                #   partition:, committed_offset:, stored_offset: }`
                def eligible_paused_partitions(min_pause_duration)
                  eligible = []

                  context.active_reports.each_value do |report|
                    next if report[:process][:status] == "stopped"

                    iterate_partitions(report) do |partition_stats, cg_id, topic_name, pt_id|
                      next unless partition_stats[:poll_state] == "paused"

                      paused_since = context.paused_since[[cg_id, topic_name, pt_id]]

                      next unless paused_since
                      next if (context.aggregated_from - paused_since) < min_pause_duration

                      eligible << {
                        cg_id: cg_id.to_s,
                        topic: topic_name.to_s,
                        partition: pt_id.to_s.to_i,
                        committed_offset: partition_stats[:committed_offset],
                        stored_offset: partition_stats[:stored_offset]
                      }
                    end
                  end

                  eligible
                end

                # @param eligible [Array<Hash>]
                # @param timeout [Integer] max time (in milliseconds) to allow the admin call to
                #   take
                # @return [Array<Hash>, nil] raw `read_partition_offsets` result, or `nil` on any
                #   failure (timeout, broker error, etc.)
                def fetch_fresh_watermarks(eligible, timeout)
                  request = Hash.new { |hash, topic_name| hash[topic_name] = [] }

                  eligible.each do |entry|
                    request[entry[:topic]] << { partition: entry[:partition], offset: :latest }
                  end

                  request.each_value { |rows| rows.uniq! { |row| row[:partition] } }

                  ::Karafka::Admin
                    .new(kafka: { "admin.max.wait.ms": timeout })
                    .read_partition_offsets(
                      request,
                      isolation_level: ::Karafka::Admin::IsolationLevels::READ_COMMITTED
                    )
                rescue
                  nil
                end

                # @param eligible [Array<Hash>]
                # @param fresh_offsets [Array<Hash>] raw `read_partition_offsets` result:
                #   `[{ topic:, partition:, offset:, timestamp:, leader_epoch: }, ...]`
                # @return [Hash] `{ cg_id => { topic => { partition_id => { lag:, lag_stored: } } } }`
                #   (string keys throughout)
                def build_paused_partitions_lag(eligible, fresh_offsets)
                  watermarks = fresh_offsets.to_h { |row| [[row[:topic], row[:partition]], row[:offset]] }
                  result = Hash.new { |hash, cg_id| hash[cg_id] = Hash.new { |h2, topic| h2[topic] = {} } }

                  eligible.each do |entry|
                    watermark = watermarks[[entry[:topic], entry[:partition]]]

                    next unless watermark

                    committed = entry[:committed_offset]
                    stored = entry[:stored_offset]

                    lag = (committed && committed >= 0) ? [watermark - committed, 0].max : nil
                    lag_stored = (stored && stored >= 0) ? [watermark - stored, 0].max : nil

                    next unless lag || lag_stored

                    result[entry[:cg_id]][entry[:topic]][entry[:partition].to_s] = {
                      lag: lag,
                      lag_stored: lag_stored
                    }.compact
                  end

                  result
                end
              end
            end
          end
        end
      end
    end
  end
end
