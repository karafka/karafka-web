# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
