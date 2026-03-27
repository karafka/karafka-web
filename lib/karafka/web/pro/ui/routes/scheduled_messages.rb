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
        module Routes
          # Manages the scheduled messages feature related routes
          class ScheduledMessages < Base
            route do |r|
              r.on "scheduled_messages" do
                r.on "schedules" do
                  controller = build(Controllers::ScheduledMessages::SchedulesController)

                  r.get String do |topic_id|
                    controller.show(topic_id)
                  end

                  r.get do
                    controller.index
                  end
                end

                r.on "explorer" do
                  r.on "topics" do
                    controller = build(Controllers::ScheduledMessages::ExplorerController)

                    r.get String do |topic_id|
                      controller.topic(topic_id)
                    end

                    r.get String, :partition_id do |topic_id, partition_id|
                      controller.partition(topic_id, partition_id)
                    end

                    # Jumps to offset matching the expected time
                    r.get String, :partition_id, "closest", Time do |topic_id, partition_id, time|
                      controller.closest(topic_id, partition_id, time)
                    end

                    # Jumps to the offset matching the expected timestamp
                    r.get(
                      String, :partition_id, "closest", Integer
                    ) do |topic_id, partition_id, timestamp|
                      # To simplify we just convert timestamp to time with ms precision
                      time = Time.at(timestamp / 1_000.0)
                      controller.closest(topic_id, partition_id, time)
                    end
                  end
                end

                r.on "messages" do
                  controller = build(Controllers::ScheduledMessages::MessagesController)

                  r.post(
                    String, :partition_id, Integer, "cancel"
                  ) do |topic_id, partition_id, message_offset|
                    controller.cancel(topic_id, partition_id, message_offset)
                  end
                end

                r.get do
                  r.redirect root_path("scheduled_messages/schedules")
                end
              end
            end
          end
        end
      end
    end
  end
end
