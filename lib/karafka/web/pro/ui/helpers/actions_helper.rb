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
          # Reasons why actions of the Web UI are not available, shared by the views that render
          # those actions disabled.
          module ActionsHelper
            # Commands that only standalone consumer processes support
            STANDALONE_COMMANDS = %i[quiet stop].freeze

            private_constant :STANDALONE_COMMANDS

            # @return [String, nil] why actions that need commanding are not available or nil when
            #   commanding is on
            def commanding_disabled_reason
              return nil if Lib::Features.commanding?

              "Commanding is disabled in the Web UI configuration"
            end

            # @return [String, nil] why topics management actions are not available or nil when
            #   topics management is on
            def topics_management_disabled_reason
              return nil if Lib::Features.topics_management?

              "Topics management is disabled in the Web UI configuration"
            end

            # @param process [Karafka::Web::Ui::Models::Process] consumer process
            # @param command [Symbol] `:trace`, `:quiet` or `:stop`
            # @return [String, nil] why the command cannot be sent to the process or nil when it
            #   can. When several reasons apply, the first one wins: commanding being off, then a
            #   command the process does not support, then the current state of the process.
            def process_command_disabled_reason(process, command)
              reason = commanding_disabled_reason
              return reason if reason

              if STANDALONE_COMMANDS.include?(command) && !standalone_process?(process)
                return "Supported only in standalone consumer processes"
              end

              case command
              when :trace
                "This process is stopped" if process.status == "stopped"
              when :quiet
                "Only a running process can be quieted" unless process.status == "running"
              when :stop
                "This process is already stopping or stopped" if %w[stopping stopped].include?(process.status)
              else
                raise ::Karafka::Errors::UnsupportedCaseError, command
              end
            end

            private

            # @param process [Karafka::Web::Ui::Models::Process] consumer process
            # @return [Boolean] true if the process runs standalone (not swarm nor embedded)
            def standalone_process?(process)
              process.execution_mode == "standalone" && !process.tags.include?("embedded")
            end
          end
        end
      end
    end
  end
end
