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
      module Mcp
        module Tools
          # Pauses a partition in a consumer group, as the Web UI partition pause action
          class PausePartition < ConsumersCommand
            tool(
              "karafka_pause_partition",
              <<~TEXT.tr("\n", " ").strip,
                Pauses one partition of a topic in a consumer group, on the process that consumes
                it, as the Web UI partition pause action does. Use karafka_consumer_groups or
                karafka_health to find it. The command is sent asynchronously.
              TEXT
              contract: Contracts::PartitionPause.new,
              operation: :produce,
              properties: TOPIC_PROPERTIES
                .merge(PARTITION_PROPERTIES)
                .merge(PAUSE_PROPERTIES),
              required: %w[consumer_group_id topic_name partition duration]
            )

            # @return [Array(String, String)] Web UI request of the matching action
            def ui_request
              ["POST", "/consumers/#{target_path}/pause"]
            end

            private

            # @return [Hash] command built from the arguments
            def command
              Ui::Lib::Consumers::Commands::Transform.partition_pause(pause_form)
            end
          end
        end
      end
    end
  end
end
