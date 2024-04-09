# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Removes the Web-UI topics from Kafka
        class DeleteTopics < Base
          # Removes the Web-UI topics
          def call
            [
              ::Karafka::Web.config.topics.consumers.states,
              ::Karafka::Web.config.topics.consumers.reports,
              ::Karafka::Web.config.topics.consumers.metrics,
              ::Karafka::Web.config.topics.consumers.commands,
              ::Karafka::Web.config.topics.errors
            ].each do |topic_name|
              if existing_topics_names.include?(topic_name.to_s)
                puts "Removing #{topic_name}..."
                ::Karafka::Admin.delete_topic(topic_name)
                puts "Topic #{topic_name} #{successfully} deleted."
              else
                puts "Topic #{topic_name} not found."
              end
            end
          end
        end
      end
    end
  end
end
