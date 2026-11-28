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
        module Helpers
          # Paths of the Pro-only sections
          module PathsHelper
            # Helps build explorer paths. We often link offsets to proper messages, etc so this
            # allows us to short-track this
            # @param args [Array<String>] sub-paths
            # @return [String] path to the expected location
            def explorer_path(*args)
              root_path(*["explorer", args.compact].flatten)
            end

            # Generates routes for explorer topics paths
            #
            # @param args [Array<String>] sub-paths
            # @return explorer topics path
            def explorer_topics_path(*args)
              explorer_path(*["topics", args.compact].flatten)
            end

            # Generates routes for explorer messages paths
            #
            # @param args [Array<String>] sub-paths
            # @return [String] explorer messages path
            def explorer_messages_path(*args)
              explorer_path(*["messages", args.compact].flatten)
            end

            # Helps build topics paths
            #
            # @return [String] topics scope path
            def topics_path(*)
              root_path("topics", *)
            end

            # Helps build per-consumer scope paths
            #
            # @param consumer_id [String] consumer process id
            # @return [String] per consumer specific path
            def consumer_path(consumer_id, *)
              consumers_path(consumer_id, *)
            end

            # Helps build scheduled messages paths.
            # Similar to the explorer helper one
            # @param topic_name [String]
            # @param partition_id [Integer, nil]
            # @param offset [Integer, nil]
            # @param action [String, nil]
            # @return [String] path to the expected location
            def scheduled_messages_explorer_path(
              topic_name = nil,
              partition_id = nil,
              offset = nil,
              action = nil
            )
              root_path(
                *[
                  "scheduled_messages",
                  "explorer",
                  "topics",
                  topic_name,
                  partition_id,
                  offset,
                  action
                ].compact
              )
            end
          end
        end
      end
    end
  end
end
