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
          module Search
            # Takes basic search parameters and normalizes the data a bit
            # Since we have fairly simple search input argument types, we can cast them easily
            # into format that we can accept further down the pipeline.
            # This module provides this normalization, so we do not have to worry about weird
            # edge cases.
            module Normalizer
              class << self
                # @param search_query [Hash] hash with expected data
                # @return [Hash] normalized search query hash
                def call(search_query)
                  {
                    phrase: search_query["phrase"].to_s,
                    limit: search_query["limit"].to_i,
                    matcher: search_query["matcher"].to_s,
                    partitions: Array(search_query["partitions"]).flatten.compact.uniq,
                    offset_type: search_query["offset_type"].to_s,
                    timestamp: search_query["timestamp"].to_i,
                    offset: search_query["offset"].to_i
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
