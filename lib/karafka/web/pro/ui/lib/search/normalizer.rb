# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Normalizer
              class << self
                def call(search_query)
                  {
                    phrase: search_query['phrase'].to_s,
                    messages: search_query['messages'].to_i,
                    strategy: search_query['strategy'].to_s,
                    partitions: Array(search_query['partitions']).flatten.compact.uniq,
                    offset_type: search_query['offset_type'].to_s,
                    timestamp: search_query['timestamp'].to_i,
                    offset: search_query['offset'].to_i,
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
