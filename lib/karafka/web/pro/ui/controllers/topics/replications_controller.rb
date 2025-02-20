# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # Controller responsible for viewing and managing topics replication details
            class ReplicationsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                leader
                replica_count
                in_sync_replica_brokers
              ].freeze

              # Displays requested topic replication details
              #
              # @param topic_name [String] topic we're interested in
              def show(topic_name)
                @topic = Models::Topic.find(topic_name)

                @partitions = refine(@topic[:partitions])

                render
              end

              # Renders form for increasing number of partitions on a topic
              def edit
                raise
              end

              # Changes number of partitions and redirects back
              def update
                raise
              end
            end
          end
        end
      end
    end
  end
end
