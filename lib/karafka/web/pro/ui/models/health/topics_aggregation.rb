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
        module Models
          module Health
            # Collapses the report-based per-partition tree from {Web::Ui::Models::Health.current}
            # into a single {AggregatedTopic} summary per topic, for the per-topic health view where
            # each topic is a single row. The consumer group level (including `:rebalanced_at`) and
            # the `cg => :topics => topic_name` shape are preserved, so the existing sorting and
            # filtering flows keep working unchanged.
            class TopicsAggregation
              class << self
                # @param state [State] current system state
                # @return [Hash] hash with per-topic aggregated statistics
                def call(state)
                  stats = Web::Ui::Models::Health.current(state)

                  stats.each_value do |cg_details|
                    cg_details[:topics].each do |topic_name, topic_details|
                      cg_details[:topics][topic_name] = AggregatedTopic.new(topic_name, topic_details)
                    end
                  end

                  stats
                end
              end
            end
          end
        end
      end
    end
  end
end
