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
