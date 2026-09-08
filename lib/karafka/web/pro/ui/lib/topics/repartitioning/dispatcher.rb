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
            module Repartitioning
              # The only side-effect of the repartitioning pipeline: increases the topic's partition
              # count.
              #
              # Any `Rdkafka::RdkafkaError` / `Rdkafka::Config::ConfigError` (for example a
              # non-increasing count) propagates so the controller can surface it on the form.
              class Dispatcher
                # @param topic_name [String] name of the topic to repartition
                # @param data [Hash] normalized repartitioning form data
                def initialize(topic_name, data)
                  @topic_name = topic_name
                  @data = data
                end

                # Increases the partition count
                # @return [void]
                def call
                  ::Karafka::Admin.create_partitions(
                    @topic_name,
                    @data[:partition_count]
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
