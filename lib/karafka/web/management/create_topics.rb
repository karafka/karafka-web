# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Creates all the needed topics (if they don't exist).
      # It does **not** populate data.
      class CreateTopics < Base
        # Runs the creation process
        #
        # @param replication_factor [Integer] replication factor for Web-UI topics
        def call(replication_factor)
          consumers_states_topic = ::Karafka::Web.config.topics.consumers.states
          consumers_metrics_topic = ::Karafka::Web.config.topics.consumers.metrics
          consumers_reports_topic = ::Karafka::Web.config.topics.consumers.reports
          errors_topic = ::Karafka::Web.config.topics.errors

          # Create only if needed
          if existing_topics_names.include?(consumers_states_topic)
            exists(consumers_states_topic)
          else
            creating(consumers_states_topic)
            # This topic needs to have one partition
            ::Karafka::Admin.create_topic(
              consumers_states_topic,
              1,
              replication_factor,
              # We care only about the most recent state, previous are irrelevant. So we can easily
              # compact after one minute. We do not use this beyond the most recent collective
              # state, hence it all can easily go away. We also limit the segment size to at most
              # 100MB not to use more space ever.
              {
                'cleanup.policy': 'compact',
                'retention.ms': 60 * 60 * 1_000,
                'segment.ms': 86_400_000, # 24h
                'segment.bytes': 104_857_600 # 10MB
              }
            )
            created(consumers_states_topic)
          end

          if existing_topics_names.include?(consumers_metrics_topic)
            exists(consumers_metrics_topic)
          else
            creating(consumers_metrics_topic)
            # This topic needs to have one partition
            # Same as states - only most recent is relevant as it is a materialized state
            ::Karafka::Admin.create_topic(
              consumers_metrics_topic,
              1,
              replication_factor,
              {
                'cleanup.policy': 'compact',
                'retention.ms': 60 * 60 * 1_000,
                'segment.ms': 86_400_000, # 24h
                'segment.bytes': 104_857_600 # 10MB
              }
            )
            created(consumers_metrics_topic)
          end

          if existing_topics_names.include?(consumers_reports_topic)
            exists(consumers_reports_topic)
          else
            creating(consumers_reports_topic)
            # This topic needs to have one partition
            ::Karafka::Admin.create_topic(
              consumers_reports_topic,
              1,
              replication_factor,
              # We do not need to to store this data for longer than 7 days as this data is only
              # used to materialize the end states
              # On the other hand we do not want to have it really short-living because in case of
              # a consumer crash, we may want to use this info to catch up and backfill the state
              { 'retention.ms': 7 * 24 * 60 * 60 * 1_000 }
            )
            created(consumers_reports_topic)
          end

          if existing_topics_names.include?(errors_topic)
            exists(errors_topic)
          else
            creating(errors_topic)
            # All the errors will be dispatched here
            # This topic can have multiple partitions but we go with one by default. A single Ruby
            # process should not crash that often and if there is an expectation of a higher volume
            # of errors, this can be changed by the end user
            ::Karafka::Admin.create_topic(
              errors_topic,
              1,
              replication_factor,
              # Remove really old errors (older than 3 months just to preserve space)
              { 'retention.ms': 3 * 31 * 24 * 60 * 60 * 1_000 }
            )
            created(errors_topic)
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
