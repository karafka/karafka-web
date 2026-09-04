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
          # Namespace for publishing (producing a brand new message) related components
          module Publishing
            # Turns normalized publish form data into the message to produce.
            #
            # The payload is produced as raw bytes (an uploaded file wins over the textarea); we do
            # not serialize it - Kafka producing takes raw bytes and Karafka has no producer-side /
            # topic serializers to apply. Header parsing lives here too; the form contract reuses
            # the `headers?` predicate so validation and transformation agree on what "valid" means.
            module Transform
              class << self
                # Builds the message hash to hand to the producer
                #
                # @param topic [String] topic we are publishing to
                # @param data [Hash] normalized form data (see {Normalizer})
                # @return [Hash] message ready for `produce_sync`
                def call(topic, data)
                  message = { topic: topic, payload: payload(data) }

                  key = data[:key]
                  message[:key] = key unless key.empty?

                  partition = data[:partition]
                  message[:partition] = partition.to_i unless partition.empty?

                  headers = headers(data[:headers])
                  message[:headers] = headers unless headers.empty?

                  message
                end

                # @param data [Hash] normalized form data
                # @return [String, nil] payload bytes to produce (a non-empty uploaded file wins
                #   over the textarea), or nil for a tombstone (e.g. to delete a key on a compacted
                #   topic)
                def payload(data)
                  return nil if data[:tombstone]

                  file = data[:payload_file]

                  # An empty/absent file must not shadow the textarea payload
                  (file.nil? || file.empty?) ? data[:payload] : file
                end

                # @param raw [String] raw headers textarea content
                # @return [Hash{String => String}] parsed headers (blank lines skipped)
                # @note Assumes the content already passed {headers?} validation.
                def headers(raw)
                  raw.each_line.each_with_object({}) do |line, acc|
                    next if line.strip.empty?

                    key, value = line.split(":", 2)

                    next if value.nil?

                    key = key.strip

                    next if key.empty?

                    acc[key] = value.strip
                  end
                end

                # @param raw [String] raw headers textarea content
                # @return [Boolean] true if every non-blank line is in the `key: value` format
                def headers?(raw)
                  raw.each_line.all? do |line|
                    next true if line.strip.empty?

                    key, value = line.split(":", 2)

                    !value.nil? && !key.strip.empty?
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
