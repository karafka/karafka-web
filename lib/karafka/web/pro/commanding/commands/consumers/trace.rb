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
        # Namespace for commands the process can react to
        module Commands
          module Consumers
            # Collects all backtraces from the available Ruby threads and publishes their details
            #   back to Kafka for debug.
            class Trace < Base
              self.name = 'consumers.trace'

              # Runs tracing and publishes result back to Kafka
              def call
                threads = {}

                Thread.list.each do |thread|
                  tid = (thread.object_id ^ ::Process.pid).to_s(36)
                  t_d = threads[tid] = {}
                  t_d[:label] = "Thread TID-#{tid} #{thread.name}"
                  t_d[:backtrace] = (thread.backtrace || ['<no backtrace available>']).join("\n")
                end

                result(threads)
              end
            end
          end
        end
      end
    end
  end
end
