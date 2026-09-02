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
          module Health
            # Configuration for the Pro aggregated Health view. Lives here (and not in the OSS
            # config) because the whole Health view is Pro-only, mirroring how search, policies and
            # branding keep their settings under their own Pro config.
            class Config
              extend ::Karafka::Core::Configurable

              # Lag related health settings
              setting :lags do
                # How many times bigger than the average a single partition's lag has to be for a
                # topic to be flagged as "skewed" in the aggregated health view. A skewed topic has
                # its lag concentrated on one (or few) hot/stuck partition(s) rather than spread
                # evenly, which needs a different response than an evenly lagging topic even when
                # the totals match.
                setting :skew_threshold, default: 3

                # Minimum biggest-partition lag below which a topic is never flagged as "skewed".
                # Without it a topic where one partition sits at 7 while the rest sit at 1 would be
                # reported as skewed, which is just noise. Only imbalances above this absolute lag
                # are worth flagging.
                setting :skew_minimum, default: 100

                # Lag at (or above) which a row is highlighted as a high-lag row in the health views
                # (a red `status-row-error` left border). Applied per partition to a partition's own
                # lag, and per topic to its average partition lag, so users can spot a runaway lag at
                # a glance from the table border.
                setting :high_threshold, default: 10_000

                # Fraction of `high_threshold` at (or above) which a row is highlighted as a warning
                # (a yellow `status-row-warning` left border) instead of an error. With the defaults
                # (10_000 and 0.5) a lag of 5_000+ is a warning and 10_000+ is an error.
                setting :warning_ratio, default: 0.5
              end

              configure
            end
          end
        end
      end
    end
  end
end
