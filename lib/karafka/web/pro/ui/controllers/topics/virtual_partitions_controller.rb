# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # Estimates how well Virtual Partitions would parallelize the data of a topic
            class VirtualPartitionsController < BaseController
              self.sortable_attributes = %w[
                partition_id
                messages
                batches
                score
                avg_speedup
                avg_active_vps
                avg_utilization
                avg_load_imbalance
                collapsed_batches
                poor_batches
                single_vp_batches
              ].freeze

              # Request params that start the estimation
              FORM_FIELDS = %i[concurrency distribution batch_size sample_size].freeze

              private_constant :FORM_FIELDS

              # Shows the estimation form and, when it was submitted, runs the estimator
              #
              # @param topic_name [String] topic we're interested in
              #
              # @note Each run reads up to `partitions x sample_size` messages inside the Web UI
              #   process, so it runs only on an explicit submit, on one page of partitions and
              #   within a time limit.
              def show(topic_name)
                ensure_visible!(topic_name)

                @topic = Models::Topic.find(topic_name)

                @active_partitions, _materialized_page, @limited = Paginators::Partitions.call(
                  @topic.partition_count, @params.current_page
                )

                next_page = @active_partitions.last < @topic.partition_count - 1
                paginate(@params.current_page, next_page)

                @form = Lib::Topics::VirtualPartitions::Normalizer.call(params)

                return render unless FORM_FIELDS.any? { |field| params.fetch(field, nil) }

                @errors = Lib::Topics::VirtualPartitions::Contracts::Form.new.call(@form).errors

                return render unless @errors.empty?

                estimate(topic_name)

                render
              end

              private

              # Runs the estimator on the active partitions within the configured time limit
              #
              # @param topic_name [String]
              def estimate(topic_name)
                timeout = Web.config.ui.topics.virtual_partitions.timeout / 1_000.0

                estimator = ::Karafka::Pro::Processing::ConsumerGroups::VirtualPartitions::Estimator.new(
                  concurrency: @form[:concurrency].to_i,
                  distribution: @form[:distribution].to_sym,
                  batch_size: @form[:batch_size].to_i,
                  sample_size: @form[:sample_size].to_i
                )

                @result = Timeout.timeout(timeout) do
                  estimator.call(topic_name, partitions: @active_partitions)
                end

                partitions = @result[:partitions].map do |partition_id, stats|
                  stats.merge(partition_id:)
                end

                # Partitions without data have no metrics and the sorter does not sort rows with
                # missing values, so they are sorted separately and listed last
                estimated, empty = partitions.partition { |stats| stats[:batches].positive? }

                @partitions = sort(estimated) + sort(empty)
              rescue Timeout::Error
                @timeout = true
              end
            end
          end
        end
      end
    end
  end
end
