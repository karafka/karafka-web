# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
