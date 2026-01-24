# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
