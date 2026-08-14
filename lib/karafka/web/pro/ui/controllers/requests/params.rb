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
        module Controllers
          # Namespace for the Pro request wrappers (params, etc.).
          module Requests
            # Extends the OSS request params with the Pro-only filtering (search) readers, so the
            # filtering query parsing never lives in the shared OSS params.
            class Params < Web::Ui::Controllers::Requests::Params
              # @return [String] filtering keyword or empty string when no filtering is requested.
              #   Supports both the plain `filter=keyword` form (keyword filtering) and the
              #   field-selectable `filter[field]=...&filter[value]=...` form (its value part).
              def current_filter
                @current_filter ||= begin
                  filter = @request_params["filter"]

                  filter.is_a?(Hash) ? filter["value"].to_s.strip : filter.to_s.strip
                end
              end

              # @return [String] the attribute selected for field-scoped filtering, or empty string
              #   when filtering across all allowed attributes (keyword filtering)
              def current_filter_field
                @current_filter_field ||= begin
                  filter = @request_params["filter"]

                  filter.is_a?(Hash) ? filter["field"].to_s.strip : ""
                end
              end
            end
          end
        end
      end
    end
  end
end
