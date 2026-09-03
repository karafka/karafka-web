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
          # Presentation helpers for the Pro-only cluster views (currently the per-broker partition
          # distribution highlighting).
          module ClusterHelper
            # Classifies a broker's leadership load against its fair share, using the configurable
            # `config.ui.cluster.distribution` ratios. The raw `load_ratio` (config-free) comes from
            # the model; the thresholds are applied here so they stay tunable.
            #
            # @param distribution [#comparable, #load_ratio] a broker distribution row
            # @return [Symbol] `:overloaded`, `:underloaded` or `:balanced`
            def broker_imbalance(distribution)
              return :balanced unless distribution.comparable

              ratios = ::Karafka::Web.config.ui.cluster.distribution

              return :overloaded if distribution.load_ratio > ratios.overloaded_ratio
              return :underloaded if distribution.load_ratio < ratios.underloaded_ratio

              :balanced
            end

            # `status-row-*` class for a broker distribution row. Only an overloaded broker gets a
            # border (yellow), since it is the actionable case; underloaded is surfaced via the
            # badge only.
            #
            # @param imbalance [Symbol] `:overloaded`, `:underloaded` or `:balanced`
            # @return [String] the row class, or an empty string
            def broker_load_status_row(imbalance)
              (imbalance == :overloaded) ? "status-row-warning" : ""
            end

            # Badge labelling a broker's load balance so an over/under-loaded node stands out.
            #
            # @param imbalance [Symbol] `:overloaded`, `:underloaded` or `:balanced`
            # @return [String] badge html (a muted dash for a balanced broker)
            def broker_load_badge(imbalance)
              case imbalance
              when :overloaded
                %(<span class="badge badge-warning">overloaded</span>)
              when :underloaded
                %(<span class="badge badge-secondary">underloaded</span>)
              else
                %(<span class="badge badge-success">balanced</span>)
              end
            end

            # Renders a broker's count of out-of-sync (under-replicated) replicas, drawing attention
            # with a warning badge when there are any.
            #
            # @param count [Integer] number of out-of-sync replicas on the broker
            # @return [String] the count, badged as a warning when positive
            def broker_out_of_sync(count)
              count.positive? ? %(<span class="badge badge-warning">#{count}</span>) : count.to_s
            end
          end
        end
      end
    end
  end
end
