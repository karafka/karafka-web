# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Wraps around the `Lib::Admin#cluster_info` with caching and some additional aliases
        # so we can reference relevant information easily
        class ClusterInfo
          class << self
            # Gets us all the cluster metadata info
            #
            # @return [Rdkafka::Metadata] cluster metadata info
            def fetch
              Karafka::Web.config.ui.cache.fetch(:cluster_info) do
                Lib::Admin.cluster_info
              end
            end

            # Returns us all the info about available topics from the cluster
            #
            # @return [Array<Ui::Models::Topic>] topics details
            def topics
              fetch
                .topics
                .map { |topic| Topic.new(topic) }
            end

            # Flattens the displayable topics into a single list of partition rows for the
            # replication view. Each row is a partition carrying its topic (and topic name, so it
            # can be sorted/filtered by name).
            #
            # @return [Array<Hash>] partition rows
            def partitions
              displayable_topics.flat_map do |topic|
                topic[:partitions].map do |partition|
                  partition.merge(
                    topic: topic,
                    topic_name: topic.fetch(:topic_name)
                  )
                end
              end
            end

            # Fetches us details about particular topic
            #
            # @param topic_name [String] name of the topic we are looking for
            # @return [Ui::Models::Topic] topic details
            def topic(topic_name)
              Lib::Admin
                .topic_info(topic_name)
                .then { |topic| Topic.new(topic) }
            rescue Rdkafka::RdkafkaError => e
              raise e unless e.code == :unknown_topic_or_part

              raise(Web::Errors::Ui::NotFoundError, topic_name)
            end

            # @param topic_name [String] name of the topic we are looking for
            # @return [Integer] number of partitions in a given topic
            def partitions_count(topic_name)
              topic(topic_name).partition_count
            end

            private

            # @return [Array<Hash>] topics to display in an alphabetical order, with internal
            #   topics excluded unless the visibility config allows them
            def displayable_topics
              all = fetch
                .topics
                .sort_by { |topic| topic[:topic_name] }

              return all if ::Karafka::Web.config.ui.visibility.internal_topics

              all.reject { |topic| topic[:topic_name].start_with?("__") }
            end
          end
        end
      end
    end
  end
end
