# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
