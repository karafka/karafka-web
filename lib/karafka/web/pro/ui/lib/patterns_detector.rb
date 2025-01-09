# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
