# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single topic data representation model
        class Topic < Lib::HashProxy
          # @return [Array<Partition>] All topic partitions data
          def partitions
            super.map do |partition_id, partition_hash|
              Partition.new(
                partition_hash.merge(partition_id: partition_id)
              )
            end
          end
        end
      end
    end
  end
end
