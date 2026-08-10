# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Routing presentation controller
        class RoutingController < BaseController
          self.sortable_attributes = %w[
            name
            active?
            value
          ].freeze

          # Routing list
          def index
            @routes = Karafka::App.routes

            @routes.each do |consumer_group|
              sort(consumer_group.topics)
            end

            render
          end

          # Given route details
          #
          # @param topic_id [String] topic id
          def show(topic_id)
            @topic = Karafka::Routing::Router.find_by(id: topic_id)

            @topic || not_found!(topic_id)

            # Present the routing settings as a flat, sortable list of name/value rows
            @details = sort(topic_detail_rows(@topic))

            render
          end

          private

          # @param topic [Karafka::Routing::Topic] topic we present the routing details for
          # @return [Array<Hash>] `{ name:, value: }` rows for every routing setting
          def topic_detail_rows(topic)
            rows = flatten_hash(topic.subscription_group.kafka, "kafka")
            rows.merge!(flatten_hash(topic.to_h.except(:kafka)))
            rows.map { |name, value| { name: name.to_s, value: value } }
          end
        end
      end
    end
  end
end
