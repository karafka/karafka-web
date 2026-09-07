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
          module Republishing
            # Builds the message to produce from the source message and the normalized form data.
            # The payload/key are copied verbatim from the source; the headers are duplicated and,
            # when requested, augmented with source-tracking headers.
            module Transform
              class << self
                # @param message [Karafka::Messages::Message] source message being republished
                # @param data [Hash] normalized form data (see {Normalizer})
                # @return [Hash] message ready for the dispatcher
                def call(message, data)
                  dispatch_message = {
                    topic: data[:target_topic],
                    payload: message.raw_payload,
                    headers: headers(message, data),
                    key: message.key
                  }

                  partition = data[:target_partition]
                  dispatch_message[:partition] = partition.to_i unless partition.empty?

                  dispatch_message
                end

                # @param message [Karafka::Messages::Message] source message
                # @param data [Hash] normalized form data
                # @return [Hash] the source headers, plus source-tracking headers when requested
                def headers(message, data)
                  headers = message.headers.dup

                  return headers unless data[:include_source_headers]

                  headers.merge(
                    "source_topic" => message.topic,
                    "source_partition" => message.partition.to_s,
                    "source_offset" => message.offset.to_s
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
