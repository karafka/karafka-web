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
        module Lib
          module Topics
            module VirtualPartitions
              # Turns the raw estimation form params into a hash of raw strings, filling the
              # values missing from the request with the estimator defaults
              #
              # Numbers are kept as strings and their format is validated by the contract, so a
              # malformed value fails validation instead of being silently truncated.
              module Normalizer
                class << self
                  # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                  # @return [Hash] estimation form data
                  def call(params)
                    app_config = ::Karafka::App.config
                    estimator_config = app_config.consumer_groups.virtual_partitions.estimator

                    {
                      concurrency: params.fetch(:concurrency, app_config.concurrency).to_s,
                      distribution: params.fetch(:distribution, estimator_config.distribution).to_s,
                      batch_size: params.fetch(:batch_size, app_config.max_messages).to_s,
                      sample_size: params.fetch(:sample_size, default_sample_size).to_s
                    }
                  end

                  private

                  # @return [Integer] estimator default sample size when it is one of the allowed
                  #   ones, otherwise the smallest allowed one
                  def default_sample_size
                    sample_sizes = Web.config.ui.topics.virtual_partitions.sample_sizes
                    default = ::Karafka::App.config.consumer_groups.virtual_partitions.estimator.sample_size

                    sample_sizes.include?(default) ? default : sample_sizes.min
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
