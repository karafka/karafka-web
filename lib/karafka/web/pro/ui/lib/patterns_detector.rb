# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for extra libs used by the Pro UI components
        module Lib
          # Checks list of topics and tries to match them against the available patterns
          # Uses the Pro detector to expand routes in the Web-UI so we include topics that are
          # or will be matched using our regular expressions
          #
          # This code **needs** to run when using deserializers of messages from patterns.
          # Otherwise default deserializer will be used instead.
          class PatternsDetector
            # Run the detection
            def call
              detector = ::Karafka::Pro::Routing::Features::Patterns::Detector.new
              topics_names = Web::Ui::Models::ClusterInfo.topics.map(&:topic_name)

              Karafka::App
                .routes
                .flat_map(&:subscription_groups)
                .each do |subscription_group|
                  sg_topics = subscription_group.topics

                  # Reject topics that are already part of routing for given subscription groups
                  # and then for remaining try to apply patterns and expand routes
                  topics_names
                    .reject { |t_name| sg_topics.any? { |rtopic| rtopic.name == t_name } }
                    .each { |t_name| detector.expand(sg_topics, t_name) }
                end
            end
          end
        end
      end
    end
  end
end
