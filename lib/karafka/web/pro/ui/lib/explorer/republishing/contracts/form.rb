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
          module Explorer
            module Republishing
              # Namespace for republishing contracts
              module Contracts
                # Validates that a message can be republished to the target topic safely: the target
                # topic exists, an explicit partition is in range, and the payload is consumable by
                # the target topic's deserializer (delegated to {Publishing::Consistency}). Rules
                # independent so all problems surface at once.
                #
                # @note Requires `target_partitions_count` and `source_message` alongside
                #   the normalized form fields.
                class Form < Web::Contracts::Base
                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("republishing_form")
                  end

                  required(:target_topic) { |val| val.is_a?(String) && !val.empty? }
                  required(:target_partition) { |val| val.is_a?(String) }

                  # The target topic must exist (its partition count could be resolved)
                  virtual do |data|
                    next if data[:target_topic].to_s.empty?
                    next unless data[:target_partitions_count].nil?

                    [[%i[target_topic], :unknown]]
                  end

                  # An explicitly requested partition must be an existing partition of the target
                  virtual do |data|
                    partition = data[:target_partition]
                    count = data[:target_partitions_count]

                    next if partition.empty?
                    next [[%i[target_partition], :out_of_range]] unless partition.match?(/\A\d+\z/)
                    next if count.nil?
                    next if partition.to_i < count

                    [[%i[target_partition], :out_of_range]]
                  end

                  # The payload must be consumable by the target deserializer, unless skipped
                  virtual do |data|
                    next if data[:skip_validation]

                    error = Publishing::Consistency.call(Transform.call(data[:source_message], data))

                    next unless error

                    [[%i[payload], error]]
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
