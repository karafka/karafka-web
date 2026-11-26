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
            # Collapses the cluster lags from {Cluster::Lags.all} into a single
            # {AggregatedClusterTopic} summary per topic, for the per-topic cluster lags view. The
            # `cg => topic_name` tree shape (and its ordering) is preserved so the existing
            # filtering and sorting flows keep working.
            class ClusterLagsAggregation
              class << self
                # @return [Hash] hash with per-topic aggregated cluster lag data
                def call
                  stats = Cluster::Lags.all

                  stats.each_value do |topics|
                    topics.each do |topic_name, partitions|
                      topics[topic_name] = AggregatedClusterTopic.new(topic_name, partitions)
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
