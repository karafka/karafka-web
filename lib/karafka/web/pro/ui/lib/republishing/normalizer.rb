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
          # Namespace for republishing (producing a copy of an existing message) components
          module Republishing
            # Coerces the raw republish request params into a typed, symbol-keyed hash the rest of
            # the republishing pipeline (contract, transform) can rely on. Coercion only.
            module Normalizer
              class << self
                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [Hash] normalized form data
                def call(params)
                  {
                    target_topic: params.fetch(:target_topic, "").to_s,
                    target_partition: params.fetch(:target_partition, "").to_s,
                    include_source_headers: truthy?(params.fetch(:include_source_headers, "")),
                    skip_validation: truthy?(params.fetch(:skip_validation, ""))
                  }
                end

                private

                # `params.bool` raises on missing keys, but a field can be absent, so we default it
                # and check the truthy values ourselves.
                #
                # @param value [Object] raw param value
                # @return [Boolean]
                def truthy?(value)
                  %w[on yes true].include?(value.to_s)
                end
              end
            end
          end
        end
      end
    end
  end
end
