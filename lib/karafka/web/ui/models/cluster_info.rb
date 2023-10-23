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
            # @param cached [Boolean] should we use cached data (true by default)
            # @return [Rdkafka::Metadata] cluster metadata info
            def fetch(cached: true)
              cache = ::Karafka::Web.config.ui.cache

              cluster_info = cache.read(:cluster_info)

              if cluster_info.nil? || !cached
                cluster_info = cache.write(:cluster_info, Lib::Admin.cluster_info)
              end

              cluster_info
            end

            # Returns us all the info about available topics from the cluster
            #
            # @param cached [Boolean] should we use cached data (true by default)
            # @return [Array<Ui::Models::Topic>] topics details
            def topics(cached: true)
              fetch(cached: cached)
                .topics
                .map { |topic| Topic.new(topic) }
            end

            # Fetches us details about particular topic
            #
            # @param topic_name [String] name of the topic we are looking for
            # @param cached [Boolean] should we use cached data (true by default)
            # @return [Ui::Models::Topic] topic details
            def topic(topic_name, cached: true)
              topics(cached: cached)
                .find { |topic_data| topic_data.topic_name == topic_name }
                .tap { |topic| topic || raise(Web::Errors::Ui::NotFoundError, topic_name) }
            end

            # @param topic_name [String] name of the topic we are looking for
            # @param cached [Boolean] should we use cached data (true by default)
            # @return [Integer] number of partitions in a given topic
            def partitions_count(topic_name, cached: true)
              topic(topic_name, cached: cached).partition_count
            end
          end
        end
      end
    end
  end
end
