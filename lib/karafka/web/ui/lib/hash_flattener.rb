# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Flattens a nested hash into a single-level hash with dotted keys, so nested structures
        # (e.g. a topic's routing settings) can be presented, sorted and filtered as a flat list of
        # name/value rows.
        module HashFlattener
          class << self
            # @param hash [Hash] hash we want to flatten
            # @param prefix [String, nil] key prefix used during recursion
            # @param result [Hash] accumulator used during recursion
            # @return [Hash] flattened `{ "a.b.c" => value }` hash
            def call(hash, prefix = nil, result = {})
              hash.each do |key, value|
                flat_key = prefix ? "#{prefix}.#{key}" : key.to_s

                case value
                when Hash
                  call(value, flat_key, result)
                when Array
                  value.each_with_index { |item, index| call({ index => item }, flat_key, result) }
                else
                  result[flat_key] = value
                end
              end

              result
            end
          end
        end
      end
    end
  end
end
