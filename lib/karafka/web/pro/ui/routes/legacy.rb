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
        module Routes
          # Redirects for paths that moved when routes were restructured, kept working so existing
          # links and bookmarks do not break. Collected here so the "current" route files are not
          # cluttered with legacy redirects.
          #
          # @note This must be bound before the routes it redirects away from. It uses full-path
          #   verb matchers (e.g. `r.get "health", "overview"`) rather than prefix matchers so a
          #   non-legacy path is left untouched and falls through to the current routes.
          class Legacy < Base
            route do |r|
              # The old top-level per-partition health views are gone; they are now per-topic
              # lenses under health/topics/<cg>/<topic>. Redirect the old paths to the aggregated
              # topics view.
              %w[overview lags offsets changes].each do |legacy_lens|
                r.get "health", legacy_lens do
                  r.redirect root_path("health/topics")
                end
              end
            end
          end
        end
      end
    end
  end
end
