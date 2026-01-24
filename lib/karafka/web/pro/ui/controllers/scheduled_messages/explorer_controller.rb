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
                           .new(@params, @session)
                           .topic(topic_id)

                render(attributes: response.attributes)
              end

              # Shows messages available in a given partition
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              def partition(topic_id, partition_id)
                response = Controllers::Explorer::ExplorerController
                           .new(@params, @session)
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
                           .new(@params, @session)
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
