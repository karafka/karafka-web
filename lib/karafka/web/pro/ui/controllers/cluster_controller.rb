# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for Pro controllers
        module Controllers
          # Cluster details controller
          class ClusterController < Web::Ui::Controllers::ClusterController
            self.sortable_attributes = %w[
              id
              name
              default?
              read_only?
              synonym?
              sensitive?
              port
            ].freeze

            # Lists available brokers in the cluster
            def index
              @brokers = refine(Models::Broker.all)

              render
            end

            # Displays selected broker configuration
            #
            # @param broker_id [String]
            def show(broker_id)
              @broker = Models::Broker.find(broker_id)

              @configs = refine(@broker.configs)

              render
            end
          end
        end
      end
    end
  end
end
