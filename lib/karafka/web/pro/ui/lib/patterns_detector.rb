# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
