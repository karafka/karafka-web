# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Updates our own observation-based bookkeeping of how long each partition has
              # been continuously reported as paused. We cannot access any process-local pause
              # timestamp (that state lives in the reporting consumer process, not here), so
              # instead we record the report time the first moment we observe
              # `poll_state == "paused"` for a given partition, and clear it the moment we see
              # it active (or no longer reported at all) again.
              class TrackPausedPartitions < Base
                include PartitionIterator

                # Updates `context.paused_since` in place
                def call
                  currently_paused = {}

                  context.active_reports.each_value do |report|
                    next if report[:process][:status] == "stopped"

                    iterate_partitions(report) do |partition_stats, cg_id, topic_name, pt_id|
                      next unless partition_stats[:poll_state] == "paused"

                      key = [cg_id, topic_name, pt_id]
                      currently_paused[key] = true
                      context.paused_since[key] ||= context.aggregated_from
                    end
                  end

                  context.paused_since.keep_if { |key, _| currently_paused.key?(key) }
                end
              end
            end
          end
        end
      end
    end
  end
end
