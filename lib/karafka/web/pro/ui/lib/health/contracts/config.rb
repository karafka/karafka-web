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
          module Health
            # Namespace with health related contracts
            module Contracts
              # Makes sure all the expected Pro Health config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                  ).fetch("en").fetch("validations").fetch("config")
                end

                nested(:ui) do
                  nested(:health) do
                    nested(:lags) do
                      # How many times bigger than the average a partition's lag has to be for the
                      # topic to be flagged as "skewed"
                      required(:skew_threshold) { |val| val.is_a?(Numeric) && val.positive? }

                      # Minimum biggest-partition lag below which a topic is never flagged as "skewed"
                      required(:skew_minimum) { |val| val.is_a?(Integer) && val >= 0 }

                      # Lag at/above which a row is highlighted as high-lag in the health views
                      required(:high_threshold) { |val| val.is_a?(Integer) && val.positive? }

                      # Fraction of `high_threshold` at/above which a row is a warning instead
                      required(:warning_ratio) do |val|
                        val.is_a?(Numeric) && val.positive? && val <= 1
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
end
