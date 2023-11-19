# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Active jobs (work) reporting controller
        class Jobs < Base
          # Lists running jobs
          def running
            current_state = Models::ConsumersState.current!
            processes = Models::Processes.active(current_state)

            # Aggregate jobs and inject the process info into them for better reporting
            jobs_total = processes.flat_map do |process|
              process.jobs.running.map do |job|
                job.to_h[:process] = process
                job
              end
            end

            @jobs, last_page = Ui::Lib::Paginations::Paginators::Arrays.call(
              jobs_total,
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end
        end
      end
    end
  end
end
