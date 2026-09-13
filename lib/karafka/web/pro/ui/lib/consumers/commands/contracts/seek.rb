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
              module Contracts
                # Validates the offset-adjustment (seek) form. The form enforces the bounds in the
                # browser; this guards the same on the server so a crafted request cannot seek to a
                # negative or out-of-range offset.
                class Seek < Web::Contracts::Base
                  # Kafka stores offsets as a signed 64-bit integer. A larger value overflows the
                  # librdkafka `int64` seek argument and raises a `RangeError` inside the running
                  # consumer when the command is applied, so we reject it server-side.
                  MAX_OFFSET = (2**63) - 1

                  private_constant :MAX_OFFSET

                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("seek_form")
                  end

                  required(:offset) do |val|
                    val.is_a?(String) && val.match?(/\A\d+\z/) && val.to_i <= MAX_OFFSET
                  end
                  required(:prevent_overtaking) { |val| [true, false].include?(val) }
                  required(:force_resume) { |val| [true, false].include?(val) }
                end
              end
            end
          end
        end
      end
    end
  end
end
