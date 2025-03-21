# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the recurring tasks feature related routes
          class RecurringTasks < Base
            route do |r|
              r.on 'recurring_tasks' do
                controller = build(Controllers::RecurringTasksController)

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
