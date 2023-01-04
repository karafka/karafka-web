# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # A simple wrapper for paginating array related data structures
        class PaginateArray
          # @param array [Array] array we want to paginate
          # @param current_page [Integer] page we want to be on
          # @return [Array<Array, <Integer, nil>>] Array with two elements: first is the array with
          #   data of the given page and second is the next page number of nil in case there is
          #   no next page (end of data)
          def call(array, current_page)
            slices = array.each_slice(per_page).to_a

            current_data = slices[current_page - 1] || []

            if slices.count >= current_page - 1 && current_data.size >= per_page
              next_page = current_page + 1
            else
              next_page = nil
            end

            [current_data, next_page]
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
