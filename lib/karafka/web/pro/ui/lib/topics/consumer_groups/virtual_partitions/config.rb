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
          module Topics
            module ConsumerGroups
              module VirtualPartitions
                # Virtual Partitions estimation settings
                class Config
                  extend ::Karafka::Core::Configurable

                  # Max time in ms for one estimation. Each run reads data from Kafka inside the
                  # Web UI process, so it needs to be bound.
                  setting :timeout, default: 30_000

                  # Numbers of most recent messages per partition users can pick to sample. We do
                  # not allow any number, so a user cannot read a whole big topic in the Web UI.
                  setting :sample_sizes, default: [
                    1_000,
                    10_000,
                    100_000
                  ]

                  # Max concurrency users can estimate for. The balanced distribution cost grows
                  # with messages x concurrency, so it needs to be bound.
                  setting :max_concurrency, default: 128

                  # Max batch size users can estimate for. Each sampled partition keeps up to one
                  # batch of messages in memory.
                  setting :max_batch_size, default: 10_000

                  configure
                end
              end
            end
          end
        end
      end
    end
  end
end
