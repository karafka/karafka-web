# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # Controller responsible for checking the data distribution in topics
            class DistributionsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                count
                share
                diff
              ].freeze

              # Displays the messages distribution across various partitions
              #
              # @param topic_name [String] topic we're interested in
              #
              # @note Because computing distribution is fairly expensive, we paginate this. While
              #   because of that results may not be exact, this allows us to support topics with
              #   many partitions.
              def show(topic_name)
                @topic = Models::Topic.find(topic_name)

                @active_partitions, _materialized_page, @limited = Paginators::Partitions.call(
                  @topic.partition_count, @params.current_page
                )

                @aggregated, distribution = @topic.distribution(@active_partitions)

                @distribution = refine(distribution)

                next_page = @active_partitions.last < @topic.partition_count - 1
                paginate(@params.current_page, next_page)

                render
              end

              def edit
                raise
              end

              def update
                raise
              end
            end
          end
        end
      end
    end
  end
end
