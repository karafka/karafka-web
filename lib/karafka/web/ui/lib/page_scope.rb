# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Abstraction on top of pagination, so we can alter pagination key and other things
        # for non-standard pagination views (non page based, etc)
        #
        # @note We do not use `_page` explicitly to indicate, that the page scope may not operate
        #   on numerable pages (1,2,3,4) but can operate on offsets or times, etc. `_offset` is
        #   more general and may refer to many types of pagination.
        class PageScope
          attr_reader :previous_offset
          attr_reader :current_offset
          attr_reader :next_offset
          attr_reader :offset_key

          # @param previous_offset [Integer] value of the previous offset/page
          # @param current_offset [Integer] current offset/page
          # @param next_offset
          # @param offset_key
          def initialize(
            previous_offset,
            current_offset,
            next_offset,
            offset_key: :page
          )
            @previous_offset = previous_offset
            @current_offset = current_offset
            @next_offset = next_offset
            @offset_key = offset_key
          end

          def paginate?
            @current_offset && (@current_offset > 1 || @next_offset)
          end

          def first_offset?
            @current_offset > 1
          end

          def first_offset
            1
          end

          def previous_offset?
            @current_offset > 1
          end

          def next_offset?
            @next_offset
          end
        end
      end
    end
  end
end
