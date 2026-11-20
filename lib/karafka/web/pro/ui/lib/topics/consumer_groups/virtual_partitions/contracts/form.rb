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
            module ConsumerGroups
              module VirtualPartitions
                # Namespace for the Virtual Partitions estimation contracts
                module Contracts
                  # Validates the Virtual Partitions estimation form before the estimator runs
                  class Form < Web::Contracts::Base
                    configure do |config|
                      config.error_messages = YAML.safe_load_file(
                        File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                      ).fetch("en").fetch("validations").fetch("consumer_groups_virtual_partitions_form")
                    end

                    # Digits only, so "5abc" is reported instead of being truncated to 5
                    COUNT_REGEXP = /\A\d+\z/

                    private_constant :COUNT_REGEXP

                    required(:concurrency) do |val|
                      next false unless val.is_a?(String) && val.match?(COUNT_REGEXP)

                      val.to_i.between?(1, Web.config.ui.topics.consumer_groups.virtual_partitions.max_concurrency)
                    end

                    required(:batch_size) do |val|
                      next false unless val.is_a?(String) && val.match?(COUNT_REGEXP)

                      val.to_i.between?(1, Web.config.ui.topics.consumer_groups.virtual_partitions.max_batch_size)
                    end

                    required(:distribution) { |val| %w[consistent balanced].include?(val) }

                    required(:sample_size) do |val|
                      next false unless val.is_a?(String) && val.match?(COUNT_REGEXP)

                      Web.config.ui.topics.consumer_groups.virtual_partitions.sample_sizes.include?(val.to_i)
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
end
