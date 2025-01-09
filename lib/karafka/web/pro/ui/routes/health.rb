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
          # Manages the health related routes
          class Health < Base
            route do |r|
              r.on 'health' do
                controller = Controllers::HealthController.new(params)

                r.get 'lags' do
                  controller.lags
                end

                r.get 'cluster_lags' do
                  controller.cluster_lags
                end

                r.get 'offsets' do
                  controller.offsets
                end

                r.get 'overview' do
                  controller.overview
                end

                r.get 'changes' do
                  controller.changes
                end

                r.get do
                  r.redirect root_path('health/overview')
                end
              end
            end
          end
        end
      end
    end
  end
end
