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
            # Controller responsible for checking the data distribution in topics
            class DistributionsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                count
                share
                diff
              ].freeze

              # After repartitioning we need to clear the cache to get fresh state
              after(:update) { cache.clear }

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

              # @param topic_name [String]
              def edit(topic_name)
                features.topics_management!

                @topic = Models::Topic.find(topic_name)

                render
              end

              # @param topic_name [String]
              def update(topic_name)
                edit(topic_name)

                partition_count = params.int(:partition_count)

                begin
                  Karafka::Admin.create_partitions(
                    topic_name,
                    partition_count
                  )
                rescue Rdkafka::RdkafkaError, Rdkafka::Config::ConfigError => e
                  @form_error = e
                end

                return edit(topic_name) if @form_error

                redirect(
                  "topics/#{topic_name}/distribution",
                  success: format_flash(
                    'Topic ? repartitioning to ? partitions successfully started',
                    topic_name,
                    partition_count
                  )
                )
              end
            end
          end
        end
      end
    end
  end
end
