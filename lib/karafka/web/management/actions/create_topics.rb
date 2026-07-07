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

            min_isr = min_insync_replicas(replication_factor)

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
                with_min_insync_replicas(errors_topic.config, min_isr)
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
                with_min_insync_replicas(consumers_reports_topic.config, min_isr)
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
                with_min_insync_replicas(consumers_metrics_topic.config, min_isr)
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
                with_min_insync_replicas(consumers_commands_topic.config, min_isr)
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
                with_min_insync_replicas(consumers_states_topic.config, min_isr)
              )
              created(consumers_states_topic.name)
            end
          end

          private

          # Reads the cluster's own broker-level `min.insync.replicas` default so it can be
          # applied explicitly to the Web UI's own topics, capped to their replication factor.
          #
          # Kafka applies the broker-level default automatically when a topic has no explicit
          # `min.insync.replicas` override, so a cluster configured for higher durability (e.g.
          # `min.insync.replicas: 2`) would silently make a topic created with
          # `replication_factor: 1` unwritable once produced to with `acks: all`. Capping the
          # explicit override to the replication factor keeps the Web UI's own topics writable
          # regardless of the cluster-wide default.
          #
          # @param replication_factor [Integer] replication factor picked for the Web UI topics
          # @return [Integer, nil] `min.insync.replicas` value safe to use, or `nil` when the
          #   cluster default could not be established, in which case no explicit override is
          #   applied and the broker default is left to apply as before
          def min_insync_replicas(replication_factor)
            broker_id = ::Karafka::Admin.cluster_info.brokers.first.fetch(:broker_id)
            resource = ::Karafka::Admin::Configs::Resource.new(type: :broker, name: broker_id.to_s)

            # Kafka-compatible systems aren't Kafka. Redpanda, Azure Event Hubs' Kafka endpoint,
            # WarpStream, and various managed proxies implement the admin protocol with varying
            # completeness. Some return a partial config set for broker resources or don't
            # support broker-level DescribeConfigs well at all, so `min.insync.replicas` may
            # simply be absent from the result. Karafka Web runs against plenty of these in the
            # wild, so we treat a missing entry as "could not be established" (see `return nil`
            # below) rather than raising.
            cluster_default = ::Karafka::Admin::Configs
              .describe(resource)
              .first
              .configs
              .find { |config| config.name == "min.insync.replicas" }
              &.value

            return nil unless cluster_default

            [Integer(cluster_default), replication_factor].min
          rescue Rdkafka::RdkafkaError
            nil
          end

          # @param topic_config [Hash] topic config as defined for a given Web UI topic
          # @param min_isr [Integer, nil] `min.insync.replicas` value to apply or `nil` if none
          #   should be applied
          # @return [Hash] topic config with `min.insync.replicas` applied when available
          def with_min_insync_replicas(topic_config, min_isr)
            return topic_config unless min_isr

            topic_config.merge("min.insync.replicas": min_isr)
          end

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
