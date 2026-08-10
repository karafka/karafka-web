# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Active jobs (work) reporting controller
        class JobsController < BaseController
          self.sortable_attributes = %w[
            id
            topic
            consumer
            type
            updated_at
          ].freeze

          # Lists running jobs
          def running
            paginate_jobs(build_jobs(:running))

            render
          end

          # Lists pending jobs
          def pending
            paginate_jobs(build_jobs(:pending))

            render
          end

          private

          # Aggregates jobs of a given type across all active processes, injecting the process info
          # into each job for better reporting.
          #
          # @param type [Symbol] `:running` or `:pending`
          # @return [Array] aggregated jobs
          def build_jobs(type)
            current_state = Models::ConsumersState.current!
            processes = Models::Processes.active(current_state)

            @jobs_counters = count_jobs_types(processes)

            processes.flat_map do |process|
              process.jobs.public_send(type).map do |job|
                job.to_h[:process] = process
                job
              end
            end
          end

          # Sorts and paginates the aggregated jobs into `@jobs`. This is the seam a Pro subclass
          # overrides to also apply filtering (a Pro-only feature); OSS only sorts.
          #
          # @param jobs_total [Array] aggregated jobs
          def paginate_jobs(jobs_total)
            @jobs, last_page = Paginators::Arrays.call(
              sort(jobs_total),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)
          end

          # @param processes [Array<Process>]
          # @return [Lib::HashProxy] particular type jobs count
          def count_jobs_types(processes)
            counts = { running: 0, pending: 0 }

            processes.flat_map do |process|
              counts[:running] += process.jobs.running.size
              counts[:pending] += process.jobs.pending.size
            end

            Lib::HashProxy.new(counts)
          end
        end
      end
    end
  end
end
