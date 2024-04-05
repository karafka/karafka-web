# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          # Kafka offset based pagination backend
          #
          # Allows us to support paginating over offsets
          class OffsetBased < Base
            # @param previous_offset [Integer, false] previous offset or false if should not be
            #   presented
            # @param current_offset [Integer] current offset
            # @param next_offset [Integer, Boolean] should we show next offset page button. If
            #   false it will not be presented.
            # @param visible_offsets [Array<Integer>] offsets that are visible in the paginated
            #   view. It is needed for the current page label
            def initialize(
              previous_offset,
              current_offset,
              next_offset,
              visible_offsets
            )
              @previous_offset = previous_offset
              @current_offset = current_offset
              @next_offset = next_offset
              @visible_offsets = visible_offsets
              super()
            end

            # Show pagination only when there is more than one page of results to be presented
            #
            # @return [Boolean]
            def paginate?
              @current_offset && (!!@previous_offset || !!@next_offset)
            end

            # @return [Boolean] active only when we are not on the first page. First page is always
            #   indicated by the current offset being -1. If there is someone that sets up the
            #   current offset to a value equal to the last message in the topic partition, we do
            #   not consider it as a first page and we allow to "reset" to -1 via the first page
            #   button
            def first_offset?
              @current_offset != -1 && @previous_offset != false
            end

            # @return [Integer] -1 because it will then select the highest offsets
            def first_offset
              -1
            end

            # @return [Boolean] Active previous page link when it is not the first page
            def previous_offset?
              !!@previous_offset
            end

            # @return [Boolean] We show current label with offsets that are present on the given
            #   page
            def current_offset?
              true
            end

            # @return [Boolean] move to the next page if not false. False indicates, that there is
            #   no next page to move to
            def next_offset?
              !!@next_offset
            end

            # If there is no next offset, we point to 0 as there should be no smaller offset than
            # that in Kafka ever
            # @return [Integer]
            def next_offset
              next_offset? ? @next_offset : 0
            end

            # @return [String] label of the current page. It is combined out of the first and
            #   the last offsets to show the range where we are. It will be empty if no offsets
            #   but this is not a problem as then we should not display pagination at all
            def current_label
              first = @visible_offsets.first
              last = @visible_offsets.last
              [first, last].compact.uniq.join(' - ').to_s
            end

            # @return [String] for offset based pagination we use the offset param name
            def offset_key
              'offset'
            end
          end
        end
      end
    end
  end
end
