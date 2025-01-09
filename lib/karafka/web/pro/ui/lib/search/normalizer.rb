# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
                    phrase: search_query['phrase'].to_s,
                    limit: search_query['limit'].to_i,
                    matcher: search_query['matcher'].to_s,
                    partitions: Array(search_query['partitions']).flatten.compact.uniq,
                    offset_type: search_query['offset_type'].to_s,
                    timestamp: search_query['timestamp'].to_i,
                    offset: search_query['offset'].to_i
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
