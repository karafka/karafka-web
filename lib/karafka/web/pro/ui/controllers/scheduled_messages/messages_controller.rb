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
            # Provides management of schedules related messages
            class MessagesController < BaseController
              # Generates a cancel request for a given schedule message
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param message_offset [Integer]
              def cancel(topic_id, partition_id, message_offset)
                # Fetches the message we want to cancel to get its key
                scheduled_message = Karafka::Admin.read_topic(
                  topic_id,
                  partition_id,
                  1,
                  message_offset
                ).first

                cancel_message = ::Karafka::Pro::ScheduledMessages.cancel(
                  key: scheduled_message.key,
                  envelope: {
                    topic: topic_id,
                    partition: partition_id
                  }
                )

                Karafka::Web.producer.produce_sync(cancel_message)

                redirect(
                  :back,
                  success: format_flash(
                    'A scheduled message with offset ? from ?#? had a ? successfully created',
                    message_offset,
                    topic_id,
                    partition_id,
                    'cancel request'
                  )
                )
              end
            end
          end
        end
      end
    end
  end
end
