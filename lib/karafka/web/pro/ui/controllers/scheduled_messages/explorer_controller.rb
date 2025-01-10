# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module ScheduledMessages
            # Allows for exploration of dispatch messages in a less generic form that via the
            # explorer as different details are present
            class ExplorerController < BaseController
              # Displays aggregated messages from (potentially) all partitions of a topic
              #
              # @param topic_id [String]
              def topic(topic_id)
                response = Controllers::Explorer::ExplorerController
                           .new(@params)
                           .topic(topic_id)

                render(attributes: response.attributes)
              end

              # Shows messages available in a given partition
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              def partition(topic_id, partition_id)
                response = Controllers::Explorer::ExplorerController
                           .new(@params)
                           .partition(topic_id, partition_id)

                render(attributes: response.attributes)
              end

              # Finds the closest offset matching the requested time and redirects to this location
              # Note, that it redirects to closest but always younger.
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param time [Time] time of the message
              def closest(topic_id, partition_id, time)
                response = Controllers::Explorer::ExplorerController
                           .new(@params)
                           .closest(topic_id, partition_id, time)

                redirect("scheduled_messages/#{response.path}")
              end
            end
          end
        end
      end
    end
  end
end
