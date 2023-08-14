# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          # Watermark offsets single message pagination engine
          #
          # It is used to provide pagination for single message displays (explorer, errors)
          class WatermarkOffsetsBased < Base
            # @param current_offset [Integer] current message offset
            # @param low_watermark_offset [Integer]
            # @param high_watermark_offset [Integer]
            def initialize(
              current_offset,
              low_watermark_offset,
              high_watermark_offset
            )
              @low_watermark_offset = low_watermark_offset
              @high_watermark_offset = high_watermark_offset
              @previous_offset = current_offset + 1
              @current_offset = current_offset
              @next_offset = current_offset - 1
              super()
            end

            # @return [Boolean] show pagination only when there are other things to present
            def paginate?
              return true if @current_offset > @low_watermark_offset
              return true if @current_offset < @high_watermark_offset - 1

              false
            end

            # @return [Boolean] provide link to the first (newest)
            def first_offset?
              @current_offset < @high_watermark_offset - 1
            end

            # @return [Integer] highest available offset
            def first_offset
              @high_watermark_offset - 1
            end

            # @return [Boolean]
            def previous_offset?
              @current_offset < @high_watermark_offset - 1
            end

            # @return [Boolean] We always show current offset
            def current_offset?
              true
            end

            # @return [String] shows as current page pagination the offset
            def current_label
              @current_offset.to_s
            end

            # @return [Boolean] if not lowest, show
            def next_offset?
              @current_offset > @low_watermark_offset
            end

            # @return [String] params offset key
            def offset_key
              'offset'
            end
          end
        end
      end
    end
  end
end
