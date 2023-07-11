# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          module Paginators
            # Paginator for selecting proper range of partitions for each page
            # For topics with a lot of partitions we cannot get all the data efficiently, that
            # is why we limit number of partitions per page and reduce the operations
            # that way. This allows us to effectively display more while not having to fetch
            # more partitions then the number of messages per page.
            # In cases like this we distribute partitions evenly part of partitions on each of
            # the pages. This may become unreliable for partitions that are not evenly
            # distributed but this allows us to display data for as many partitions as we want
            # without overloading the system
            class Partitions < Base
              class << self
                # Computers the partitions slice, materialized page and the limitations status
                # for a given page
                # @param partitions_count [Integer] number of partitions for a given topic
                # @param current_page [Integer] current page
                # @return [Array<Array<Integer>, Integer, Boolean>] list of partitions that should
                #   be active on a given page, materialized page for them and info if we had to
                #   limit the partitions number on a given page
                def call(partitions_count, current_page)
                  # How many "chunks" of partitions we will have
                  slices_count = (partitions_count / per_page.to_f).ceil
                  # How many partitions in a single slice should we have
                  in_slice = (partitions_count / slices_count.to_f).ceil
                  # Which "chunked" page do we want to get
                  materialized_page = (current_page / slices_count.to_f).ceil
                  # Which slice is the one we are operating on
                  active_slice_index = (current_page - 1) % slices_count
                  # All available slices so we can pick one that is active
                  partitions_slices = (0...partitions_count).each_slice(in_slice).to_a
                  # Select active partitions only
                  active_partitions = partitions_slices[active_slice_index]
                  # Are we limiting ourselves because of partition count
                  limited = slices_count > 1

                  [active_partitions, materialized_page, limited]
                end
              end
            end
          end
        end
      end
    end
  end
end
