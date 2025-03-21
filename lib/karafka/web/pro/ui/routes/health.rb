# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the health related routes
          class Health < Base
            route do |r|
              r.on 'health' do
                controller = build(Controllers::HealthController)

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
