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
          module Consumers
            module Commands
              # Namespace for the consumer commanding form contracts
              module Contracts
                # Validates the pause form (both partition and topic level). Duration is in seconds
                # with `0` meaning an indefinite pause, so it only needs to be a non-negative int
                # within range.
                class Pause < Web::Contracts::Base
                  # Duration is given in seconds and multiplied by 1_000 to milliseconds downstream
                  # before it reaches the running consumer's pause timeout. Cap it so the resulting
                  # millisecond value stays within a signed 64-bit integer.
                  MAX_DURATION = ((2**63) - 1) / 1_000

                  private_constant :MAX_DURATION

                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("pause_form")
                  end

                  required(:duration) do |val|
                    val.is_a?(String) && val.match?(/\A\d+\z/) && val.to_i <= MAX_DURATION
                  end
                  required(:prevent_override) { |val| [true, false].include?(val) }
                end
              end
            end
          end
        end
      end
    end
  end
end
