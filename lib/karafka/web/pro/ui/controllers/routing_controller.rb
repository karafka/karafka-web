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
        module Controllers
          # Routing details - same as in OSS
          class RoutingController < BaseController
            self.sortable_attributes = %w[
              name
              active?
            ].freeze

            # Routing list
            def index
              detect_patterns_routes

              @routes = Karafka::App.routes

              @routes.each do |consumer_group|
                refine(consumer_group.topics)
              end

              render
            end

            # Given route details
            #
            # @param topic_id [String] topic id
            def show(topic_id)
              detect_patterns_routes

              @topic = Karafka::Routing::Router.find_by(id: topic_id)

              @topic || not_found!(topic_id)

              render
            end

            private

            # Detect routes defined as patterns
            def detect_patterns_routes
              Lib::PatternsDetector.new.call
            end
          end
        end
      end
    end
  end
end
