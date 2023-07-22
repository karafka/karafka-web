# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          # Regular page-based pagination engine
          class PageBased < Base
            # @param current_offset [Integer] current page
            # @param show_next_offset [Boolean] should we show next page
            #   (value is computed automatically)
            def initialize(
              current_offset,
              show_next_offset
            )
              @previous_offset = current_offset - 1
              @current_offset = current_offset
              @next_offset = show_next_offset ? current_offset + 1 : false
              super()
            end

            # Show pagination only when there is more than one page
            # @return [Boolean]
            def paginate?
              @current_offset && (@current_offset > 1 || !!@next_offset)
            end

            # @return [Boolean] active the first page link when we are not on the first page
            def first_offset?
              @current_offset > 1
            end

            # @return [Boolean] first page for page based pagination is always empty as it moves us
            #   to the initial page so we do not include any page info
            def first_offset
              false
            end

            # @return [Boolean] Active previous page link when it is not the first page
            def previous_offset?
              @current_offset > 1
            end

            # @return [Boolean] always show current offset pagination value
            def current_offset?
              true
            end

            # @return [String] label of the current page
            def current_label
              @current_offset.to_s
            end

            # @return [Boolean] move to the next page if not false. False indicates, that there is
            #   no next page to move to
            def next_offset?
              @next_offset
            end

            # @return [String] for page pages pagination, always use page as the url value
            def offset_key
              'page'
            end
          end
        end
      end
    end
  end
end
