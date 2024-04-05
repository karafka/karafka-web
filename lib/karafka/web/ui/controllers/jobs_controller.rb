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
            current_state = Models::ConsumersState.current!
            processes = Models::Processes.active(current_state)

            @jobs_counters = count_jobs_types(processes)

            # Aggregate jobs and inject the process info into them for better reporting
            jobs_total = processes.flat_map do |process|
              process.jobs.running.map do |job|
                job.to_h[:process] = process
                job
              end
            end

            @jobs, last_page = Paginators::Arrays.call(
              refine(jobs_total),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end

          # Lists pending jobs
          def pending
            current_state = Models::ConsumersState.current!
            processes = Models::Processes.active(current_state)

            @jobs_counters = count_jobs_types(processes)

            # Aggregate jobs and inject the process info into them for better reporting
            jobs_total = processes.flat_map do |process|
              process.jobs.pending.map do |job|
                job.to_h[:process] = process
                job
              end
            end

            @jobs, last_page = Paginators::Arrays.call(
              refine(jobs_total),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end

          private

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
