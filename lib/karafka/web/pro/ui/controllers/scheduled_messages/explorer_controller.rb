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
        module Controllers
          module ScheduledMessages
            # Allows for exploration of dispatch messages in a less generic form that via the
            # explorer as different details are present
            class ExplorerController < BaseController
              # Displays aggregated messages from (potentially) all partitions of a topic
              #
              # @param topic_id [String]
              def topic(topic_id)
                response = Controllers::ExplorerController
                           .new(@params)
                           .topic(topic_id)

                render(attributes: response.attributes)
              end

              # Shows messages available in a given partition
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              def partition(topic_id, partition_id)
                response = Controllers::ExplorerController
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
                response = Controllers::ExplorerController
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
