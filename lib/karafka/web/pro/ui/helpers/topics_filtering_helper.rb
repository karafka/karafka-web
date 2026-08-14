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
          # View-level filtering of topic collections for the routing and per-process subscriptions
          # views. Unlike the generic {FilteringHelper} (which renders the search box) and the
          # [[Filter]] engine (which prunes per-request structures in place), this narrows the live
          # `Karafka::App.routes` / process subscriptions non-destructively, since those must never
          # be mutated.
          module TopicsFilteringHelper
            # Non-destructively narrows a topics collection (routing or a consumer subscription)
            # down to the ones matching the current filter.
            #
            # It is field aware: when the `topic` field is selected only topic names are matched;
            # when `consumer_group`/`subscription_group` is selected the whole collection is kept or
            # dropped based on that group's name. With no explicit field (plain keyword) a topic is
            # kept when its own name matches or when any of the provided group labels match.
            #
            # It always returns a new array and leaves the source untouched.
            #
            # @param topics [Enumerable] topics of a subscription/consumer group
            # @param consumer_group [String, nil] the consumer group name shown as the section title
            # @param subscription_group [String, nil] the subscription group name (subscriptions)
            # @return [Array] all topics when no filtering is active, otherwise only matching ones
            def visible_topics(topics, consumer_group: nil, subscription_group: nil)
              return topics.to_a unless filtering?

              keyword = params.current_filter.downcase
              by_name = -> { topics.select { |topic| topic.name.to_s.downcase.include?(keyword) } }
              label_match = ->(label) { label.to_s.downcase.include?(keyword) }

              case params.current_filter_field
              when "consumer_group"
                label_match.call(consumer_group) ? topics.to_a : []
              when "subscription_group"
                label_match.call(subscription_group) ? topics.to_a : []
              when "topic"
                by_name.call
              else
                # Plain keyword: match the topic name or any of the group labels
                [consumer_group, subscription_group].any?(&label_match) ? topics.to_a : by_name.call
              end
            end
          end
        end
      end
    end
  end
end
