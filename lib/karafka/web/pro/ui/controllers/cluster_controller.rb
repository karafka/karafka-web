# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Cluster details controller
          class ClusterController < Web::Ui::Controllers::ClusterController
            # This Pro controller inherits the OSS cluster controller (which has no filtering), so it
            # pulls in the Pro-only filtering concern directly
            include Filterable

            self.sortable_attributes = %w[
              id
              name
              default?
              read_only?
              synonym?
              sensitive?
              port
            ].freeze

            # Each action renders different columns, so we scope the filterable fields per action to
            # what it actually displays (`replication` is inherited from the OSS controller)
            self.filterable_attributes = {
              index: %i[id name],
              show: %i[name value],
              replication: %i[topic_name]
            }.freeze

            # Lists available brokers in the cluster
            def index
              @brokers = filter(sort(Models::Broker.all))

              render
            end

            # Displays selected broker configuration
            #
            # @param broker_id [String]
            def show(broker_id)
              @broker = Models::Broker.find(broker_id)

              @configs = filter(sort(@broker.configs))

              render
            end

            private

            # Adds Pro-only filtering on top of the OSS sort/paginate seam
            #
            # @param partitions_total [Array<Hash>] partition rows
            def paginate_partitions(partitions_total)
              @partitions, last_page = Paginators::Arrays.call(
                filter(sort(partitions_total)),
                @params.current_page
              )

              paginate(@params.current_page, !last_page)
            end
          end
        end
      end
    end
  end
end
