# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Topics
            # Delegates the topic resume request into the topic changes tracker and dispatches the
            # acceptance message back to Kafka. This command resumes all partitions of a given topic
            # within a specific consumer group. Matchers filter which processes handle the command.
            class Resume < Base
              self.name = 'topics.resume'

              # Dispatches the resume request into the appropriate handler and indicates that the
              # resuming is in an acceptance state
              def call
                Handlers::Topics::Tracker.instance << command

                # Publish back info on who did this with all the details for inspection
                acceptance(command.to_h)
              end
            end
          end
        end
      end
    end
  end
end
