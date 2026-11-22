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
          # Base for the tools that send a command to consumer processes, as the Web UI
          # commanding actions do
          class ProcessCommand < Base
            # Process id argument of the tools that command one process
            PROCESS_ID = {
              process_id: {
                type: "string",
                description: "Id of the consumer process, as listed by karafka_processes"
              }
            }.freeze

            # Commanding must be enabled, as for the Web UI commanding actions
            def authorize!
              deny!("Commanding is disabled") unless Ui::Lib::Features.commanding?
            end

            # @return [Array(String, String)] Web UI request of the matching commanding action
            def ui_request
              process_id = @arguments[:process_id]
              action = self.class.command.name.split(".").last

              path = process_id ? "#{process_id}/#{action}" : "#{action}_all"

              ["POST", "/consumers/commanding/#{path}"]
            end

            # @return [Array<String>] the commands topic
            def topics
              [::Karafka::Web.config.topics.consumers.commands.name]
            end

            private

            # @return [Hash] dispatched command details
            def fetch
              Commanding::Dispatcher.request(self.class.command.name, {}, matchers: matchers)

              { dispatched: true }.merge(plan)
            end

            # @return [Hash] command the tool would send and to which processes
            def plan
              process_id = @arguments[:process_id]

              {
                command: self.class.command.name,
                processes: process_id ? [process_id] : "all"
              }
            end

            # @return [Hash] matchers of the processes that should run the command
            def matchers
              process_id = @arguments[:process_id]

              process_id ? { process_id: process_id } : {}
            end
          end
        end
      end
    end
  end
end
