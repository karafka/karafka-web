# frozen_string_literal: true

module Karafka
  module Web
    # Responsible for setup of the Web UI and Karafka Web-UI related components initialization.
    class Installer
      # Defaults stats state that we create in Kafka
      DEFAULT_STATS = {
        batches: 0,
        messages: 0,
        retries: 0,
        dead: 0,
        busy: 0,
        enqueued: 0,
        processing: 0,
        threads_count: 0,
        processes: 0,
        rss: 0,
        listeners_count: 0,
        utilization: 0,
        lag_stored: 0,
        errors: 0
      }.freeze

      # Default empty historicals for first record in Kafka
      DEFAULT_AGGREGATED = Processing::Consumers::TimeSeriesTracker::TIME_RANGES
                           .keys
                           .map { |range| [range, []] }
                           .to_h
                           .freeze

      # WHole default empty state (aside from dispatch time)
      DEFAULT_STATE = {
        processes: {},
        stats: DEFAULT_STATS
      }.freeze

      private_constant :DEFAULT_STATS, :DEFAULT_AGGREGATED, :DEFAULT_STATE

      # Creates needed topics and the initial zero state, so even if no `karafka server` processes
      # are running, we can still display the empty UI
      #
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def bootstrap!(replication_factor: 1)
        bootstrap_topics!(replication_factor)
        bootstrap_consumers_states!
      end

      # Removes all the Karafka topics and creates them again with the same replication factor
      def reset!
        states_topic = ::Karafka::Web.config.topics.consumers.states
        replication_factor = ::Karafka::Admin
                             .cluster_info
                             .topics
                             .find { |topic| topic[:topic_name] == states_topic }
                             .fetch(:partitions)
                             .first
                             .fetch(:replica_count)

        uninstall!
        bootstrap!(replication_factor: replication_factor)
      end

      # Removes all the Karafka Web topics
      def uninstall!
        [
          ::Karafka::Web.config.topics.consumers.states,
          ::Karafka::Web.config.topics.consumers.reports,
          ::Karafka::Web.config.topics.errors
        ].each { |topic_name| ::Karafka::Admin.delete_topic(topic_name) }
      end

      # Adds the extra needed consumer group, topics and routes for Web UI to be able to operate
      def enable!
        ::Karafka::App.routes.draw do
          web_deserializer = ::Karafka::Web::Deserializer.new

          consumer_group ::Karafka::Web.config.processing.consumer_group do
            # Topic we listen on to materialize the states
            topic ::Karafka::Web.config.topics.consumers.reports do
              config(active: false)
              active ::Karafka::Web.config.processing.active
              # Since we materialize state in intervals, we can poll for half of this time without
              # impacting the reporting responsiveness
              max_wait_time ::Karafka::Web.config.processing.interval / 2
              max_messages 1_000
              consumer ::Karafka::Web::Processing::Consumer
              # This needs to be true in order not to reload the consumer in dev. This consumer
              # should not be affected by the end user development process
              consumer_persistence true
              deserializer web_deserializer
              manual_offset_management true
              # Start from the most recent data, do not materialize historical states
              # This prevents us from dealing with cases, where client id would be changed and
              # consumer group name would be renamed and we would start consuming all historical
              initial_offset 'latest'
            end

            # We define those three here without consumption, so Web understands how to deserialize
            # them when used / viewed
            topic ::Karafka::Web.config.topics.consumers.states do
              config(active: false)
              active false
              deserializer web_deserializer
            end

            topic ::Karafka::Web.config.topics.consumers.metrics do
              config(active: false)
              active false
              deserializer web_deserializer
            end

            topic ::Karafka::Web.config.topics.errors do
              config(active: false)
              active false
              deserializer web_deserializer
            end
          end
        end

        # Installs all the consumer related listeners
        ::Karafka::Web.config.tracking.consumers.listeners.each do |listener|
          ::Karafka.monitor.subscribe(listener)
        end

        # Installs all the producer related listeners
        ::Karafka::Web.config.tracking.producers.listeners.each do |listener|
          ::Karafka.producer.monitor.subscribe(listener)
        end
      end

      private

      # Creates all the needed topics for the admin UI to work
      #
      # @param replication_factor [Integer]
      def bootstrap_topics!(replication_factor = 1)
        existing_topics = ::Karafka::Admin.cluster_info.topics.map { |topic| topic[:topic_name] }

        consumers_states_topic = ::Karafka::Web.config.topics.consumers.states
        consumers_metrics_topic = ::Karafka::Web.config.topics.consumers.metrics
        consumers_reports_topic = ::Karafka::Web.config.topics.consumers.reports
        errors_topic = ::Karafka::Web.config.topics.errors

        # Create only if needed
        unless existing_topics.include?(consumers_states_topic)
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
        end

        unless existing_topics.include?(consumers_metrics_topic)
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
        end

        unless existing_topics.include?(consumers_reports_topic)
          # This topic needs to have one partition
          ::Karafka::Admin.create_topic(
            consumers_reports_topic,
            1,
            replication_factor,
            # We do not need to to store this data for longer than 7 days as this data is only used
            # to materialize the end states
            # On the other hand we do not want to have it really short-living because in case of a
            # consumer crash, we may want to use this info to catch up and backfill the state
            { 'retention.ms': 7 * 24 * 60 * 60 * 1_000 }
          )
        end

        unless existing_topics.include?(errors_topic)
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
        end
      end

      # Creates the initial state record with all values being empty
      def bootstrap_consumers_states!
        ::Karafka.producer.produce_sync(
          topic: Karafka::Web.config.topics.consumers.states,
          key: Karafka::Web.config.topics.consumers.states,
          payload: DEFAULT_STATE.to_json
        )

        ::Karafka.producer.produce_sync(
          topic: Karafka::Web.config.topics.consumers.metrics,
          key: Karafka::Web.config.topics.consumers.metrics,
          payload: {
            aggregated: DEFAULT_AGGREGATED,
            consumer_groups: DEFAULT_AGGREGATED
          }.to_json
        )
      end
    end
  end
end
