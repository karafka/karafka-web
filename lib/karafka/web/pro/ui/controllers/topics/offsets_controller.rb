# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # Controller responsible for viewing topics offsets details
            class OffsetsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                low
                high
                diff
              ].freeze

              # Displays high and low offsets for given topic
              #
              # @param topic_name [String] topic we're interested in
              def show(topic_name)
                @topic = Models::Topic.find(topic_name)

                @active_partitions, _materialized_page, @limited = Paginators::Partitions.call(
                  @topic.partition_count, @params.current_page
                )

                offsets = @active_partitions.map do |partition_id|
                  part_offsets = Admin.read_watermark_offsets(topic_name, partition_id)

                  {
                    partition_id: partition_id,
                    low: part_offsets.first,
                    high: part_offsets.last,
                    diff: part_offsets.last - part_offsets.first
                  }
                end

                @offsets = refine(offsets)

                next_page = @active_partitions.last < @topic.partition_count - 1
                paginate(@params.current_page, next_page)

                render
              end
            end
          end
        end
      end
    end
  end
end
