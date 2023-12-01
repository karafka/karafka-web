# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Routing presentation controller
        class Routing < Base
          self.sortable_attributes = %w[
            name
            active?
          ].freeze

          # Routing list
          def index
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
            @topic = Karafka::Routing::Router.find_by(id: topic_id)

            @topic || raise(::Karafka::Web::Errors::Ui::NotFoundError, topic_id)

            render
          end
        end
      end
    end
  end
end
