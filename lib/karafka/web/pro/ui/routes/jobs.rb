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
