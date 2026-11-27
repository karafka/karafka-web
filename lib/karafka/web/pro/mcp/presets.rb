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
        # Named sets of changing tools for `config.mcp.changing_tools`. A preset lists its tools by
        # name, so a release that adds a changing tool does not enable it in apps using a preset
        module Presets
          # Operations that can be reverted: pause and resume, trace, quiet a process, trigger a
          # recurring task and republish a message (for example from a DLQ)
          OPERATE = %w[
            karafka_pause_partition
            karafka_resume_partition
            karafka_pause_topic
            karafka_resume_topic
            karafka_trace_process
            karafka_quiet_process
            karafka_trigger_recurring_task
            karafka_republish_message
          ].freeze

          # Presets by name
          ALL = { operate: OPERATE }.freeze

          private_constant :OPERATE, :ALL

          class << self
            # @param name [Symbol] preset name
            # @return [Boolean] is there such a preset
            def exists?(name)
              ALL.key?(name)
            end

            # @return [Array<String>] names of all the changing tools the presets know
            def names
              ALL.values.flatten.uniq
            end

            # @param setting [Symbol, Array<String>] `config.mcp.changing_tools` value
            # @return [Array<String>] names of the changing tools it enables
            def tools(setting)
              setting.is_a?(Symbol) ? ALL.fetch(setting) : setting
            end
          end
        end
      end
    end
  end
end
