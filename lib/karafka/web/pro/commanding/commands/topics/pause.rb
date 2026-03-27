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
      module Commanding
        module Commands
          # Namespace for topic-level command execution within a consumer group context
          module Topics
            # Delegates the topic pause request into the topic changes tracker and dispatches the
            # acceptance message back to Kafka. This command pauses all partitions of a given topic
            # within a specific consumer group. Matchers filter which processes handle the command.
            class Pause < Base
              self.name = "topics.pause"

              # Delegates the pause request to async handling
              def call
                Handlers::Topics::Tracker.instance << command

                acceptance(command.to_h)
              end
            end
          end
        end
      end
    end
  end
end
