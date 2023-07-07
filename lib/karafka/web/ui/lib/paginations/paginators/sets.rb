# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          module Paginators
            module Sets
              class << self
                # @param array [Array] array we want to paginate
                # @param current_page [Integer] page we want to be on
                # @return [Array<Array, Boolean>] Array with two elements: first is the array with
                #   data of the given page and second is a boolean flag with info if the elements we got
                #   are from the last page
                def call(counts, current_page)
                  total_elements = counts.sum
                  first_global_index = (current_page - 1) * per_page
                  last_global_index = [first_global_index + per_page, total_elements].min

                  set_indices_map = Hash.new { |h, k| h[k] = [] }

                  (first_global_index...last_global_index).each do |global_index|
                    set_index = global_index % counts.size
                    element_index = global_index / counts.size
                    set_indices_map[set_index] << element_index if element_index < counts[set_index]
                  end

                  set_indices_map.map do |set, indices|
                    {
                      set: set,
                      indices: indices.min...indices.max + 1
                    }
                  end
                end

                private

                # @return [Integer] how many elements should we display in the UI
                def per_page
                  ::Karafka::Web.config.ui.per_page
                end
              end
            end
          end
        end
      end
    end
  end
end
