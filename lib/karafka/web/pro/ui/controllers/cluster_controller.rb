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
            # @param broker_id [String] id of the broker
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
