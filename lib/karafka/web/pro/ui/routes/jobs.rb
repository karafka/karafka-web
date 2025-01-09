# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the jobs related routes
          class Jobs < Base
            route do |r|
              r.on 'jobs' do
                controller = Controllers::JobsController.new(params)

                r.get 'running' do
                  controller.running
                end

                r.get 'pending' do
                  controller.pending
                end

                r.redirect root_path('jobs/running')
              end
            end
          end
        end
      end
    end
  end
end
