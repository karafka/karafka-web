# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Creates all the needed topics (if they don't exist).
        # It does **not** populate data.
        class CreateTopics < Base
          # Runs the creation process
          #
          # @param replication_factor [Integer] replication factor for Web-UI topics
          #
          # @note The order of creation of those topics is important. In order to support the
          #   zero-downtime bootstrap, we use the presence of the states topic and its initial
          #   state existence as an indicator that the setup went as expected. It the consumers
          #   states topic exists and contains needed data, it means all went as expected and that
          #   topics created before it also exist (as no error).
          def call(replication_factor)
            consumers_states_topic = ::Karafka::Web.config.topics.consumers.states
            consumers_metrics_topic = ::Karafka::Web.config.topics.consumers.metrics
            consumers_reports_topic = ::Karafka::Web.config.topics.consumers.reports
            consumers_commands_topic = ::Karafka::Web.config.topics.consumers.commands
            errors_topic = ::Karafka::Web.config.topics.errors

            if existing_topics_names.include?(errors_topic.name)
              exists(errors_topic.name)
            else
              creating(errors_topic.name)
              # All the errors will be dispatched here
              # This topic can have multiple partitions but we go with one by default. A single
              # Ruby process should not crash that often and if there is an expectation of a higher
              # volume of errors, this can be changed by the end user
              ::Karafka::Admin.create_topic(
                errors_topic.name,
                1,
                replication_factor,
                errors_topic.config
              )
              created(errors_topic.name)
            end

            if existing_topics_names.include?(consumers_reports_topic.name)
              exists(consumers_reports_topic.name)
            else
              creating(consumers_reports_topic.name)
              # This topic needs to have one partition
              ::Karafka::Admin.create_topic(
                consumers_reports_topic.name,
                1,
                replication_factor,
                consumers_reports_topic.config
              )
              created(consumers_reports_topic.name)
            end

            if existing_topics_names.include?(consumers_metrics_topic.name)
              exists(consumers_metrics_topic.name)
            else
              creating(consumers_metrics_topic.name)
              # This topic needs to have one partition
              # Same as states - only most recent is relevant as it is a materialized state
              ::Karafka::Admin.create_topic(
                consumers_metrics_topic.name,
                1,
                replication_factor,
                consumers_metrics_topic.config
              )
              created(consumers_metrics_topic.name)
            end

            if existing_topics_names.include?(consumers_commands_topic.name)
              exists(consumers_commands_topic.name)
            else
              creating(consumers_commands_topic.name)
              # Commands are suppose to live short and be used for controlling processes and some
              # debug. Their data can be removed safely fast.
              ::Karafka::Admin.create_topic(
                consumers_commands_topic.name,
                1,
                replication_factor,
                consumers_commands_topic.config
              )
              created(consumers_commands_topic.name)
            end

            # Create only if needed
            if existing_topics_names.include?(consumers_states_topic.name)
              exists(consumers_states_topic.name)
            else
              creating(consumers_states_topic.name)
              # This topic needs to have one partition
              ::Karafka::Admin.create_topic(
                consumers_states_topic.name,
                1,
                replication_factor,
                consumers_states_topic.config
              )
              created(consumers_states_topic.name)
            end
          end

          private

          # @param topic_name [String] name of the topic that exists
          # @return [String] formatted message
          def exists(topic_name)
            puts("Topic #{topic_name} #{already} exists.")
          end

          # @param topic_name [String] name of the topic that we are creating
          # @return [String] formatted message
          def creating(topic_name)
            puts("Creating topic #{topic_name}...")
          end

          # @param topic_name [String] name of the topic that we created
          # @return [String] formatted message
          def created(topic_name)
            puts("Topic #{topic_name} #{successfully} created.")
          end
        end
      end
    end
  end
end
