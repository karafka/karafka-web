# frozen_string_literal: true

<<<<<<< HEAD
# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.
=======
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
>>>>>>> 1afda33fb7dc6e935eac73cb420f22c127068896

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the recurring tasks feature related routes
          class RecurringTasks < Base
            route do |r|
              r.on 'recurring_tasks' do
                controller = Controllers::RecurringTasksController.new(params)

                r.get 'schedule' do
                  controller.schedule
                end

                r.get 'logs' do
                  controller.logs
                end

                r.post 'trigger_all' do
                  controller.trigger_all
                end

                r.post 'enable_all' do
                  controller.enable_all
                end

                r.post 'disable_all' do
                  controller.disable_all
                end

                r.post String, 'trigger' do |task_id|
                  controller.trigger(task_id)
                end

                r.post String, 'enable' do |task_id|
                  controller.enable(task_id)
                end

                r.post String, 'disable' do |task_id|
                  controller.disable(task_id)
                end

                r.get do
                  r.redirect root_path('recurring_tasks/schedule')
                end
              end
            end
          end
        end
      end
    end
  end
end
