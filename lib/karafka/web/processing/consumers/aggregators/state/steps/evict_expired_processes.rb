# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Evicts expired processes from the current state.
              #
              # We consider processes dead if they do not report often enough.
              #
              # @note We do not evict based on status (stopped), because we want to report the
              #   stopped processes for extra time within the ttl limitations. This makes
              #   tracking of things from UX perspective nicer.
              class EvictExpiredProcesses < Base
                # Deletes ttl-expired entries from `context.state[:processes]` and
                # `context.active_reports`
                def call
                  max_ttl = context.aggregated_from - (::Karafka::Web.config.ttl / 1_000)

                  context.state[:processes].delete_if do |_id, details|
                    details[:dispatched_at] < max_ttl
                  end

                  context.active_reports.delete_if do |_id, details|
                    details[:dispatched_at] < max_ttl
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
