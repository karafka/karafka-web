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
        module Lib
          module Publishing
            # Checks that a payload would be consumable by the topic's configured deserializer.
            #
            # Karafka has no producer-side serializers, but a topic in the routing does have a
            # (consume-side) deserializer. Running it over the user's bytes is a validity check: if
            # the deserializer raises, the payload does not meet what the topic's consumers expect.
            #
            # It is best-effort and only runs when the topic is in the routing (with an active
            # deserializer). Unrouted topics and tombstones (nil payload) are skipped.
            module Consistency
              # Minimal message stand-in exposing what payload deserializers read from a message.
              Message = Struct.new(:raw_payload, :headers, :key)

              class << self
                # @param message [Hash] the built message (see {Transform.call})
                # @return [String, nil] an error description when the payload is not consumable, or
                #   nil when it is consistent / could not be checked
                def call(message)
                  payload = message[:payload]

                  # Tombstones (nil payload) are always valid
                  return nil if payload.nil?

                  deserializer = payload_deserializer(message[:topic])

                  return nil unless deserializer

                  runner = Lib::SafeRunner.new do
                    deserializer.call(Message.new(payload, message[:headers] || {}, message[:key]))
                  end
                  runner.call

                  return nil if runner.success?

                  "Payload does not match what the topic's consumers expect: #{runner.error.message}"
                end

                private

                # @param topic_name [String] topic we are publishing to
                # @return [Object, nil] the topic's payload deserializer, or nil when the topic is
                #   not in the routing (nothing to validate against)
                def payload_deserializer(topic_name)
                  topic = ::Karafka::Routing::Router.find_by(name: topic_name)

                  return nil unless topic
                  return nil unless topic.deserializers?

                  topic.deserializers.payload
                end
              end
            end
          end
        end
      end
    end
  end
end
