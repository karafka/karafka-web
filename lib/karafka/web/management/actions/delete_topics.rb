# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Removes the Web-UI topics from Kafka
        class DeleteTopics < Base
          # Removes the Web-UI topics
          #
          # @param mcp_audit [Boolean] should the MCP audit topic be removed as well. Reset keeps
          #   it, so the incident trail survives a state reset
          def call(mcp_audit: true)
            topics = [
              ::Karafka::Web.config.topics.consumers.states.name,
              ::Karafka::Web.config.topics.consumers.reports.name,
              ::Karafka::Web.config.topics.consumers.metrics.name,
              ::Karafka::Web.config.topics.consumers.commands.name,
              ::Karafka::Web.config.topics.errors.name
            ]

            topics << ::Karafka::Web.config.topics.mcp_audit.name if mcp_audit

            topics.each do |topic_name|
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
