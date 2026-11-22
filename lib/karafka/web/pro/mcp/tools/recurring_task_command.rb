# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Mcp
        module Tools
          # Base for the tools that trigger, enable or disable recurring tasks, as the Web UI
          # recurring tasks actions do
          class RecurringTaskCommand < Base
            # Task id argument of the tools that command one task
            TASK_ID = {
              task_id: { type: "string", description: "Id of the task, as in the Web UI schedule" }
            }.freeze

            # @return [Array(String, String)] Web UI request of the matching recurring tasks action
            def ui_request
              task_id = @arguments[:task_id]
              action = self.class.command

              ["POST", task_id ? "/recurring_tasks/#{task_id}/#{action}" : "/recurring_tasks/#{action}_all"]
            end

            # @return [Array<String>] the recurring tasks schedules topic
            def topics
              [::Karafka::App.config.recurring_tasks.topics.schedules.name]
            end

            private

            # @return [Hash] dispatched command details
            def fetch
              task_id = @arguments.fetch(:task_id, "*")

              ensure_task_exists!(task_id) unless task_id == "*"

              ::Karafka::Pro::RecurringTasks.public_send(self.class.command, task_id)

              { dispatched: true, command: self.class.command.to_s, task_id: task_id }
            end

            # @param task_id [String]
            # @raise [Errors::Mcp::NoDataError] when the task is not in the current schedule
            def ensure_task_exists!(task_id)
              schedule = Web::Ui::Models::RecurringTasks::Schedule.current

              return if schedule && schedule.tasks.map(&:id).include?(task_id)

              raise Errors::Mcp::NoDataError, "Task #{task_id} is not in the current schedule"
            end
          end
        end
      end
    end
  end
end
