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
          module Publishing
            # Coerces the raw publish request params into a typed, symbol-keyed hash the rest of the
            # publishing pipeline (contract, transform) can rely on. Coercion only, no validation.
            module Normalizer
              class << self
                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [Hash] normalized form data
                def call(params)
                  {
                    payload: params.fetch(:payload, "").to_s,
                    payload_file: uploaded_bytes(params),
                    tombstone: truthy?(params.fetch(:tombstone, "")),
                    key: params.fetch(:key, "").to_s,
                    partition: params.fetch(:partition, "").to_s,
                    headers: params.fetch(:headers, "").to_s
                  }
                end

                private

                # `params.bool` raises on missing keys, but the field is absent on the initial form
                # render, so we default it and check the truthy values ourselves.
                #
                # @param value [Object] raw param value
                # @return [Boolean]
                def truthy?(value)
                  %w[on yes true].include?(value.to_s)
                end

                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [String, nil] uploaded file bytes or nil when no file was uploaded
                def uploaded_bytes(params)
                  file = params.fetch(:payload_file, nil)

                  return nil unless file.is_a?(Hash)

                  tempfile = file[:tempfile]

                  return nil unless tempfile

                  tempfile.read
                end
              end
            end
          end
        end
      end
    end
  end
end
