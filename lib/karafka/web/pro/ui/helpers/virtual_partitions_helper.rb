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
        module Helpers
          # Presentation helpers for the Virtual Partitions estimation views
          module VirtualPartitionsHelper
            # @param verdict [Symbol, nil] estimator verdict
            # @return [String] badge class for the verdict
            def vp_verdict_badge(verdict)
              case verdict
              when :recommended then "badge-success"
              when :maybe then "badge-warning"
              when :not_recommended then "badge-error"
              else "badge-secondary"
              end
            end

            # @param verdict [Symbol, nil] estimator verdict
            # @return [String] human readable verdict
            def vp_verdict_label(verdict)
              verdict ? verdict.to_s.tr("_", " ").capitalize : "None"
            end

            # @param value [Numeric, nil] metric value
            # @param suffix [String] suffix to add to the value, e.g. a unit
            # @return [String] value with the suffix or a dash when there is no value
            def vp_metric(value, suffix = "")
              value.nil? ? "-" : "#{value}#{suffix}"
            end
          end
        end
      end
    end
  end
end
