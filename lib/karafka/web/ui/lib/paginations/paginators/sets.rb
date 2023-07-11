# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          module Paginators
            # Paginator that allows us to take several lists/sets and iterate over them in a
            # round-robin fashion.
            #
            # It does not have to iterate over all the elements from each set for higher pages
            # making it much more effective than the naive implementation.
            class Sets < Base
              class << self
                # @param counts [Array<Integer>] sets elements counts
                # @param current_page [Integer] page number
                # @return [Hash<Integer, Range>] hash with integer keys indicating the count
                #   location and the range needed to be taken of elements (counting backwards) for
                #   each partition
                def call(counts, current_page)
                  return {} if current_page < 1

                  lists = counts.dup.map.with_index { |el, i| [i, el] }

                  curr_item_index = 0
                  curr_list_index = 0
                  items_to_skip_count = per_page * (current_page - 1)

                  loop do
                    lists_count = lists.length
                    return {} if lists_count.zero?

                    shortest_list_count = lists.map(&:last).min
                    mover = (shortest_list_count - curr_item_index)
                    items_we_are_considering_count = lists_count * mover

                    if items_we_are_considering_count >= items_to_skip_count
                      curr_item_index += items_to_skip_count / lists_count
                      curr_list_index = items_to_skip_count % lists_count
                      break
                    else
                      curr_item_index = shortest_list_count
                      lists.delete_if { |x| x.last == shortest_list_count }
                      items_to_skip_count -= items_we_are_considering_count
                    end
                  end

                  page_items = []
                  largest_list_count = lists.map(&:last).max

                  while page_items.length < per_page && curr_item_index < largest_list_count
                    curr_list = lists[curr_list_index]

                    if curr_item_index < curr_list.last
                      page_items << [curr_list.first, curr_item_index]
                    end

                    curr_list_index += 1
                    if curr_list_index == lists.length
                      curr_list_index = 0
                      curr_item_index += 1
                    end
                  end

                  hashed = Hash.new { |h, k| h[k] = [] }

                  page_items.each do |el|
                    hashed[el.first] << el.last
                  end

                  hashed.each do |key, value|
                    hashed[key] = (value.first..value.last)
                  end

                  hashed
                end
              end
            end
          end
        end
      end
    end
  end
end
