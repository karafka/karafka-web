# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          # Shared context container for status checks.
          #
          # This class holds cached data that is shared across multiple status checks.
          # Instead of each check fetching data independently, they share this context
          # to avoid redundant Kafka calls and ensure consistency.
          #
          # The context provides:
          # - Memoized accessors for expensive data (cluster info, state, metrics)
          # - Helper methods for topic name configuration
          # - Computed topic details based on cluster info
          #
          # @example Using context in a check
          #   class MyCheck < Base
          #     def call
          #       # Access shared data
          #       context.current_state
          #       context.cluster_info
          #
          #       # Use topic helpers
          #       context.topics_consumers_states
          #     end
          #   end
          class Context
            # @return [Object, nil] cluster metadata from Kafka
            attr_accessor :cluster_info

            # @return [Float, nil] time in milliseconds to connect to Kafka
            attr_accessor :connection_time

            # @return [Hash, nil] current consumers state from Kafka
            attr_accessor :current_state

            # @return [Hash, nil] current consumers metrics from Kafka
            attr_accessor :current_metrics

            # @return [Array, nil] list of active processes
            attr_accessor :processes

            # @return [Array, nil] list of topic subscriptions
            attr_accessor :subscriptions

            # Returns the consumers states topic name from configuration.
            #
            # @return [String] the configured consumers states topic name
            def topics_consumers_states
              ::Karafka::Web.config.topics.consumers.states.name.to_s
            end

            # Returns the consumers reports topic name from configuration.
            #
            # @return [String] the configured consumers reports topic name
            def topics_consumers_reports
              ::Karafka::Web.config.topics.consumers.reports.name.to_s
            end

            # Returns the consumers metrics topic name from configuration.
            #
            # @return [String] the configured consumers metrics topic name
            def topics_consumers_metrics
              ::Karafka::Web.config.topics.consumers.metrics.name.to_s
            end

            # Returns the errors topic name from configuration.
            #
            # @return [String] the configured errors topic name
            def topics_errors
              ::Karafka::Web.config.topics.errors.name
            end

            # Computes and returns details about all Web UI topics.
            #
            # For each topic, returns whether it exists, its partition count,
            # and replication factor. Uses cluster_info to determine actual values.
            #
            # @return [Hash] hash with topic names as keys and detail hashes as values
            # @example Return value
            #   {
            #     'karafka_consumers_states' => { present: true, partitions: 1, replication: 3 },
            #     'karafka_consumers_reports' => { present: false, partitions: 0, replication: 1 }
            #   }
            def topics_details
              @topics_details ||= compute_topics_details
            end

            # Clears the memoized topics_details cache.
            #
            # Call this if cluster_info is updated and you need fresh topic details.
            def clear_topics_details_cache
              @topics_details = nil
            end

            private

            # Computes topic details from cluster info.
            #
            # @return [Hash] topic details hash
            def compute_topics_details
              base = { present: false, partitions: 0, replication: 1 }

              topics = {
                topics_consumers_states => base.dup,
                topics_consumers_reports => base.dup,
                topics_consumers_metrics => base.dup,
                topics_errors => base.dup
              }

              return topics unless cluster_info

              cluster_info.topics.each do |topic|
                name = topic[:topic_name]

                next unless topics.key?(name)

                topics[name].merge!(
                  present: true,
                  partitions: topic[:partition_count],
                  replication: topic[:partitions].map { |part| part[:replica_count] }.max
                )
              end

              topics
            end
          end
        end
      end
    end
  end
end
