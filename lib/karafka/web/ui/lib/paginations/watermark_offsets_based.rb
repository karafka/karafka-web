# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          class WatermarkOffsetsBased < Base
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

            def paginate?
              return true if @current_offset > @low_watermark_offset
              return true if @current_offset < @high_watermark_offset - 1

              false
            end

            def first_offset?
              @current_offset < @high_watermark_offset - 1
            end

            def first_offset
              @high_watermark_offset - 1
            end

            def previous_offset?
              @current_offset < @high_watermark_offset - 2
            end

            def current_offset?
              true
            end

            def current_label
              @current_offset.to_s
            end

            def next_offset?
              @current_offset > @low_watermark_offset
            end

            def offset_key
              'offset'
            end
          end
        end
      end
    end
  end
end
