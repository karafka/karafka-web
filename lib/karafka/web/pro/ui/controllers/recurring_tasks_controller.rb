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
                command(action, '*')

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
              ::Karafka::App.config.recurring_tasks.topics.logs
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

              "The #{command_name} command has been dispatched to the #{task_id} task."
            end

            # Generates a nice flash message about dispatch of multi-task command
            # @param command [Symbol]
            # @return [String] flash message that command has been dispatched
            def dispatched_to_all(command)
              command_name = command.to_s.capitalize

              "The #{command_name} command has been dispatched to all tasks."
            end
          end
        end
      end
    end
  end
end
