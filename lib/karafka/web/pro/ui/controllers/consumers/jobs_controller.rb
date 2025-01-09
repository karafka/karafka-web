# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Displays details about given consumer jobs
            #
            # @note There is a separate jobs controller for jobs overview, this one is per consumer
            #   specific.
            class JobsController < ConsumersController
              self.sortable_attributes = %w[
                topic
                consumer
                type
                messages
                first_offset
                last_offset
                committed_offset
                updated_at
              ].freeze

              # Shows all running jobs of a consumer
              # @param process_id [String]
              def running(process_id)
                details(process_id)

                @running_jobs = @process.jobs.running

                refine(@running_jobs)

                render
              end

              # Shows all pending jobs of a consumer
              # @param process_id [String]
              def pending(process_id)
                details(process_id)

                @pending_jobs = @process.jobs.pending

                refine(@pending_jobs)

                render
              end
            end
          end
        end
      end
    end
  end
end
