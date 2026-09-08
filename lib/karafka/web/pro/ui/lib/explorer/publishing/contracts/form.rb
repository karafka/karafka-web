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
            module Publishing
              # Namespace for publishing contracts
              module Contracts
                # Validates that a normalized publish form can be sent to Kafka safely. Field-format
                # rules cover the shape of the input; the header rule delegates to {Transform} (so
                # validation and transformation agree), and the payload rule delegates to
                # {Consistency} for the runtime deserializer cross-check. Rules are independent (not
                # gated on prior errors) so all problems surface in a single submission.
                #
                # @note Requires `topic`, `partitions_count` and `skip_validation` in the data
                #   alongside the normalized form fields.
                class Form < Web::Contracts::Base
                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("publishing_form")
                  end

                  required(:payload) { |val| val.is_a?(String) }
                  required(:key) { |val| val.is_a?(String) }
                  required(:partition) { |val| val.is_a?(String) }
                  required(:headers) { |val| val.is_a?(String) }

                  optional(:payload_file) { |val| val.nil? || val.is_a?(String) }

                  # Every non-blank header line must be in the `key: value` format
                  virtual do |data|
                    next if Transform.headers?(data[:headers])

                    [[%i[headers], :invalid_format]]
                  end

                  # An explicitly requested partition must be an existing partition of the topic. When
                  # the partition count is not supplied we cannot range-check, so we skip rather than
                  # reject.
                  virtual do |data|
                    partition = data[:partition]
                    partitions_count = data[:partitions_count]

                    next if partition.empty?
                    next [[%i[partition], :out_of_range]] unless partition.match?(/\A\d+\z/)
                    next if partitions_count.nil?
                    next if partition.to_i < partitions_count

                    [[%i[partition], :out_of_range]]
                  end

                  # The payload must be consumable by the topic's deserializer (the runtime check that
                  # lets this contract answer "can this be sent to Kafka safely?"). Delegated to
                  # {Consistency}, which is skipped for unrouted topics and tombstones. The user can
                  # opt out via `skip_validation`. The dynamic message is used verbatim.
                  virtual do |data|
                    next if data[:skip_validation]

                    error = Consistency.call(Transform.call(data[:topic], data))

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
