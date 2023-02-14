# frozen_string_literal: true

module Karafka
  module Web
    # Responsible for setup of the Web UI and Karafka Web-UI related components initialization.
    class Installer
      # Creates needed topics and the initial zero state, so even if no `karafka server` processes
      # are running, we can still display the empty UI
      #
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def bootstrap!(replication_factor: 1)
        bootstrap_topics!(replication_factor)
        bootstrap_state!
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
              # Since we materialize state in intervals, we can poll for half of this time without
              # impacting the reporting responsiveness
              max_wait_time ::Karafka::Web.config.processing.interval / 2
              max_messages 1_000
              consumer ::Karafka::Web::Processing::Consumer
              deserializer web_deserializer
              manual_offset_management true
            end

            # We define those two here without consumption, so Web understands how to deserialize
            # them when used / viewed
            topic ::Karafka::Web.config.topics.consumers.states do
              active false
              deserializer web_deserializer
            end

            topic ::Karafka::Web.config.topics.errors do
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
        consumers_reports_topic = ::Karafka::Web.config.topics.consumers.reports
        errors_topic = ::Karafka::Web.config.topics.errors

        # Create only if needed
        unless existing_topics.include?(consumers_states_topic)
          # This topic needs to have one partition
          ::Karafka::Admin.create_topic(
            consumers_states_topic,
            1,
            replication_factor,
            # We care only about the most recent state, previous are irrelevant
            { 'cleanup.policy': 'compact' }
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
            replication_factor
          )
        end

        bootstrap_state!
      end

      # Creates the initial state record with all values being empty
      def bootstrap_state!
        ::Karafka.producer.produce_sync(
          topic: Karafka::Web.config.topics.consumers.states,
          key: Karafka::Web.config.topics.consumers.states,
          payload: {
            processes: {},
            stats: {
              batches: 0,
              messages: 0,
              errors: 0,
              retries: 0,
              dead: 0,
              busy: 0,
              enqueued: 0,
              threads_count: 0,
              processes: 0,
              rss: 0,
              listeners_count: 0,
              utilization: 0
            }
          }.to_json
        )
      end
    end
  end
end
