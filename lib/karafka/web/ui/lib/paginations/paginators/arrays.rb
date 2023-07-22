# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          # Namespace for commands that build paginated resources based on the provided page
          module Paginators
            # A simple wrapper for paginating array related data structures
            # We call this with plural (same with `Sets`) to avoid confusion with Ruby classes
            class Arrays < Base
              class << self
                # @param array [Array] array we want to paginate
                # @param current_page [Integer] page we want to be on
                # @return [Array<Array, Boolean>] Array with two elements: first is the array with
                #   data of the given page and second is a boolean flag with info if the elements we got
                #   are from the last page
                def call(array, current_page)
                  slices = array.each_slice(per_page).to_a
                  current_data = slices[current_page - 1] || []
                  last_page = !(slices.count >= current_page - 1 && current_data.size >= per_page)

                  [current_data, last_page]
                end
              end
            end
          end
        end
      end
    end
  end
end
