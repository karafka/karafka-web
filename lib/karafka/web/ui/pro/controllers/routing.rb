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
    module Ui
      module Pro
        module Controllers
          # Routing details - same as in OSS
          class Routing < Ui::Controllers::Routing
            self.sortable_attributes = %w[
              name
              active?
            ].freeze

            # Routing list
            def index
              detect_patterns_routes

              @routes = Karafka::App.routes

              @routes.each do |consumer_group|
                consumer_group.subscription_groups.each do |subscription_group|
                  refine(consumer_group.topics)
                end
              end

              render
            end

            # Given route details
            #
            # @param topic_id [String] topic id
            def show(topic_id)
              detect_patterns_routes

              @topic = Karafka::Routing::Router.find_by(id: topic_id)

              @topic || raise(::Karafka::Web::Errors::Ui::NotFoundError, topic_id)

              render
            end

            private

            # Checks list of topics and tries to match them against the available patterns
            # Uses the Pro detector to expand routes in the Web-UI so we include topics that are
            # or will be matched using our regular expressions
            def detect_patterns_routes
              detector = ::Karafka::Pro::Routing::Features::Patterns::Detector.new
              topics_names = Models::ClusterInfo.topics.map(&:topic_name)

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
