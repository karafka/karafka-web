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
          module Cluster
            # Namespace with cluster related contracts
            module Contracts
              # Makes sure all the expected Pro cluster config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                  ).fetch("en").fetch("validations").fetch("config")
                end

                nested(:ui) do
                  nested(:cluster) do
                    nested(:distribution) do
                      # How many times its fair share a broker must lead to be flagged overloaded
                      required(:overloaded_ratio) { |val| val.is_a?(Numeric) && val.positive? }

                      # Fraction of its fair share below which a broker is flagged underloaded
                      required(:underloaded_ratio) { |val| val.is_a?(Numeric) && val.positive? }
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
