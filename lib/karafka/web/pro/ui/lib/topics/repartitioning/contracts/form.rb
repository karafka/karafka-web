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
                # Validates the "increase partitions" form: the value is a positive integer and it
                # is an actual increase over the topic's current partition count.
                #
                # `create_partitions` sets the TOTAL count, so anything at or below the current
                # count is not an increase. The broker rejects it anyway, but only as a raw
                # rdkafka error - catching it here re-renders the form with a field error, which
                # is what the form's own `min` and helper text already promise.
                #
                # @note The comparison needs `current_partition_count` alongside the normalized
                #   form fields; it is skipped when that is not supplied.
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

                  # Must be a real increase. Shape problems are already reported by the rule above,
                  # so a malformed value is skipped here rather than reported twice
                  virtual do |data|
                    count = data[:partition_count]
                    current = data[:current_partition_count]

                    next if current.nil?
                    # Mirror the shape rule above: anything it already rejects (malformed, or
                    # below 1) is reported there, so this must stay silent rather than replace
                    # that error with a less accurate one
                    next unless count.is_a?(String) && count.match?(COUNT_REGEXP)
                    next unless count.to_i >= 1
                    next if count.to_i > current

                    [[%i[partition_count], :not_an_increase]]
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
