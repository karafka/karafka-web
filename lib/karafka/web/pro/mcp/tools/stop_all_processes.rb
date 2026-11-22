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
          # Asks all consumer processes to stop, as the Web UI Stop All action
          class StopAllProcesses < ProcessCommand
            sends Commanding::Commands::Consumers::Stop

            tool(
              "karafka_stop_all_processes",
              <<~TEXT.tr("\n", " ").strip,
                Asks all consumer processes to finish their work and shut down, as the Web UI
                Stop All action does.
              TEXT
              contract: Contracts::Destructive.new,
              operation: :produce,
              idempotent: true,
              destructive: true
            )
          end
        end
      end
    end
  end
end
