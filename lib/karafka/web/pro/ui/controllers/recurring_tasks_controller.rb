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
          # Controller for viewing and managing recurring tasks
          class RecurringTasksController < Web::Ui::Controllers::ClusterController
            self.sortable_attributes = %w[
              id
              enabled
              cron
              previous_time
              next_time
            ].freeze

            # Displays the current schedule
            def schedule
              @schedule = Models::RecurringTasks::Schedule.current

              @tasks = refine(@schedule.tasks) if @schedule

              render
            end

            # Displays the execution logs
            def logs
              @watermark_offsets = Models::WatermarkOffsets.find(logs_topic, 0)
              previous_offset, @logs, next_offset, = current_page_data

              paginate(
                previous_offset,
                @params.current_offset,
                next_offset,
                @logs.map(&:offset)
              )

              # We remap this so we can represent the payloads as logs that we expect
              @logs.map! { |log| Models::RecurringTasks::Log.new(log.payload) }

              render
            end

            # Actions definitions that trigger appropriate recurring tasks action + display a nice
            # flash message.
            %i[
              trigger
              enable
              disable
            ].each do |action|
              define_method :"#{action}_all" do
                command(action, "*")

                redirect(
                  :back,
                  success: dispatched_to_all(action)
                )
              end

              define_method action do |task_id|
                command(action, task_id)

                redirect(
                  :back,
                  success: dispatched_to_one(action, task_id)
                )
              end
            end

            private

            # @return [Array] Array with requested messages as well as pagination details and other
            #   obtained metadata
            def current_page_data
              Models::Message.offset_page(
                logs_topic,
                0,
                @params.current_offset,
                @watermark_offsets
              )
            end

            # @return [String] recurring tasks logs topic
            def logs_topic
              ::Karafka::App.config.recurring_tasks.topics.logs.name
            end

            # Runs the recurring tasks command
            #
            # @param command [String] command we want to invoke
            # @param task_id [String] task id or '*' to target expected task
            def command(command, task_id)
              Karafka::Pro::RecurringTasks.public_send(command, task_id)
            end

            # Generates a nice flash message about the dispatch
            # @param command [Symbol]
            # @param task_id [String]
            # @return [String] flash message that command has been dispatched to a given task
            def dispatched_to_one(command, task_id)
              command_name = command.to_s.capitalize

              format_flash(
                "The ? command has been dispatched to the ? task",
                command_name,
                task_id
              )
            end

            # Generates a nice flash message about dispatch of multi-task command
            # @param command [Symbol]
            # @return [String] flash message that command has been dispatched
            def dispatched_to_all(command)
              command_name = command.to_s.capitalize

              format_flash(
                "The ? command has been dispatched to all tasks",
                command_name
              )
            end
          end
        end
      end
    end
  end
end
