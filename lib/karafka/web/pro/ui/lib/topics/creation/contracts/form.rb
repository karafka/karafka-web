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
            module Creation
              # Namespace for the topic creation form contracts
              module Contracts
                # Validates the "create topic" form. Mirrors the browser-side constraints (a valid
                # Kafka topic name and positive partition/replication counts) so a crafted request
                # gets a friendly error instead of a raw broker rejection.
                class Form < Web::Contracts::Base
                  # Characters Kafka allows in a topic name: letters, digits, dots, hyphens and
                  # underscores
                  TOPIC_NAME_REGEXP = /\A[a-zA-Z0-9._-]+\z/

                  # Maximum length of a Kafka topic name
                  MAX_TOPIC_NAME_LENGTH = 249

                  private_constant :TOPIC_NAME_REGEXP, :MAX_TOPIC_NAME_LENGTH

                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("topic_creation_form")
                  end

                  required(:topic_name) do |val|
                    val.is_a?(String) &&
                      !val.empty? &&
                      val.length <= MAX_TOPIC_NAME_LENGTH &&
                      val.match?(TOPIC_NAME_REGEXP)
                  end

                  required(:partitions_count) { |val| val.is_a?(Integer) && val >= 1 }
                  required(:replication_factor) { |val| val.is_a?(Integer) && val >= 1 }
                end
              end
            end
          end
        end
      end
    end
  end
end
