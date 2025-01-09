# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the cluster related routes
          class Cluster < Base
            route do |r|
              r.on 'cluster' do
                controller = Controllers::ClusterController.new(params)

                r.get 'replication' do
                  # We use the non-pro controller here because this action is the same
                  controller = Ui::Controllers::ClusterController.new(params)
                  controller.replication
                end

                r.get String do |broker_id|
                  controller.show(broker_id)
                end

                r.get do
                  controller.index
                end
              end
            end
          end
        end
      end
    end
  end
end
