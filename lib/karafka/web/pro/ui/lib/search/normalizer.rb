# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
