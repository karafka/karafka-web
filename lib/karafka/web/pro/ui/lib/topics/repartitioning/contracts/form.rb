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
            module Repartitioning
              # Namespace for the repartitioning form contracts
              module Contracts
                # Validates the "increase partitions" form. Whether the new count is actually higher
                # than the current one is left to the broker (rejects a non-increase); this only
                # guards the value being a positive integer before we reach out.
                class Form < Web::Contracts::Base
                  # Digits only. The count arrives as a raw string so a malformed value ("5abc",
                  # "3.9", " 7") is reported as such instead of being silently truncated
                  COUNT_REGEXP = /\A\d+\z/

                  private_constant :COUNT_REGEXP

                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("repartitioning_form")
                  end

                  required(:partition_count) do |val|
                    val.is_a?(String) && val.match?(COUNT_REGEXP) && val.to_i >= 1
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
