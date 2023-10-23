# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Model used for accessing watermark offsets
        class WatermarkOffsets < Lib::HashProxy
          class << self
            # Retrieve watermark offsets for given topic partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @return [WatermarkOffsets]
            def find(topic_id, partition_id)
              offsets = Lib::Admin.read_watermark_offsets(topic_id, partition_id)

              new(
                low: offsets.first,
                high: offsets.last
              )
            end
          end

          # @return [Boolean] true if given partition never had any messages and is empty
          def empty?
            low.zero? && high.zero?
          end

          # @return [Boolean] true if given partition had data but all of it was removed due
          #   to log retention and compaction policies
          def cleaned?
            !empty? && low == high
          end
        end
      end
    end
  end
end
