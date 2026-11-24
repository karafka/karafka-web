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
          # Partitions details presentation of the Pro views
          module PartitionsHelper
            # @param topic_name [String] name of the topic for explorer path
            # @param partition_id [Integer] partition for the explorer path
            # @param offset [Integer] offset
            # @param explore [Boolean] should we link the offset to the message in the Explorer
            # @return [String] offset, linked to the Explorer when requested, or `N/A` with labeled
            #   explanation for offsets that were not yet committed
            def offset_with_label(topic_name, partition_id, offset, explore: false)
              return super(topic_name, partition_id, offset) if !explore || offset.negative?

              path = explorer_topics_path(topic_name, partition_id, offset)
              %(<a href="#{path}">#{offset}</a>)
            end

            # @param details [::Karafka::Web::Ui::Models::Partition] partition information with
            #   lso risk state info
            # @return [String] background classes for row marking
            def lso_risk_state_bg(details)
              case details.lso_risk_state
              when :active
                ""
              when :at_risk
                "bg-warning bg-opacity-25"
              when :stopped
                "bg-error bg-opacity-25"
              else
                raise ::Karafka::Errors::UnsupportedCaseError
              end
            end

            # Normalizes the metric value for display. Negative values coming from statistics
            # usually mean, that the value is not (yet) available.
            #
            # @param value [Integer]
            # @return [String] input value if not negative or N/A
            def normalized_metric(value)
              value.negative? ? "N/A" : value.to_s
            end
          end
        end
      end
    end
  end
end
