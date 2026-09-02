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
          # Presentation helpers for the Pro-only aggregated Health view. They classify lag values
          # and per-row trouble state into `status-row-*` border classes so users can spot problems
          # at a glance. Lives in Pro (not the shared OSS helpers) because the Health view is
          # Pro-only, as is its `config.ui.health.lags` configuration.
          module HealthHelper
            # Classifies a lag value against the configured high-lag threshold, for at-a-glance row
            # highlighting. The threshold marks an error; `warning_ratio` of it marks a warning.
            #
            # @param lag [Integer] a lag value (a partition's lag, or a topic's average lag)
            # @return [Symbol, nil] `:error`, `:warning` or nil (nil also for N/A / negative lags)
            def lag_severity(lag)
              return nil if lag.negative?

              lags = ::Karafka::Web.config.ui.health.lags

              return :error if lag >= lags.high_threshold
              return :warning if lag >= lags.high_threshold * lags.warning_ratio

              nil
            end

            # `status-row-*` class for a row based purely on a lag value (used where there is no
            # other per-row status, e.g. cluster lag partitions).
            #
            # @param lag [Integer] lag value to classify
            # @return [String] `status-row-error`/`status-row-warning`, or an empty string
            def lag_status_row(lag)
              severity = lag_severity(lag)

              severity ? "status-row-#{severity}" : ""
            end

            # `status-row-*` class for an aggregated topic row. High lag wins, but a skewed topic
            # and (for report-based rows) a topic with paused partitions are also surfaced as
            # warnings even when the average lag is not high on its own.
            #
            # @param topic_stats [#avg_lag, #skewed?] an aggregated topic row (report or cluster)
            # @param paused [Boolean] whether the topic has any paused partition (report rows only;
            #   cluster lag rows have no poll state so this stays false)
            # @return [String] `status-row-error`/`status-row-warning`, or an empty string
            def topic_lag_status_row(topic_stats, paused: false)
              severity = lag_severity(topic_stats.avg_lag)
              severity ||= :warning if topic_stats.skewed? || paused

              severity ? "status-row-#{severity}" : ""
            end

            # `status-row-*` class for a per-partition report row. Combines several trouble signals,
            # worst first: a high lag or a stopped process is an error (red); a warning-level lag, a
            # paused partition or a winding-down process is a warning (yellow). A healthy running
            # partition keeps the plain process status class (no border).
            #
            # @param details [::Karafka::Web::Ui::Models::Partition] partition information
            # @return [String] the `status-row-*` class for the row
            def partition_status_row(details)
              severity = lag_severity(details.lag_hybrid)

              return "status-row-error" if severity == :error
              return "status-row-stopped" if details.process.status == "stopped"
              return "status-row-warning" if severity == :warning || details.poll_state != "active"

              "status-row-#{details.process.status}"
            end
          end
        end
      end
    end
  end
end
