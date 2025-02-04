# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            module Partitions
              class PausesController < BaseController
                self.sortable_attributes = %w[].freeze

                def toggle(process_id, subscription_group_id, topic, partition_id)
                  subscriptions(process_id)
                  bootstrap!(@process.consumer_groups, process_id, subscription_group_id, topic, partition_id)

                  render
                end

                def create(process_id, subscription_group_id, topic, partition_id)
                  toggle(process_id, subscription_group_id, topic, partition_id)

                  render
                end

                def delete(process_id, subscription_group_id, topic, partition_id)
                  toggle(process_id, subscription_group_id, topic, partition_id)

                  render
                end
              end
            end
          end
        end
      end
    end
  end
end
