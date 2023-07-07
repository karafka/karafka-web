# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class ClusterInfo
          class << self
            def fetch(cached: true)
              cache = ::Karafka::Web.config.ui.cache

              cluster_info = cache.read(:cluster_info)

              if cluster_info.nil? || !cached
                cluster_info = cache.write(:cluster_info, Karafka::Admin.cluster_info)
              end

              cluster_info
            end

            def topics(cached: true)
              fetch(cached: cached).topics
            end

            def topic(topic_name, cached: true)
              topics(cached: cached)
                .find { |topic_data| topic_data[:topic_name] == topic_name }
                .tap { |topic| topic || raise(Web::Errors::Ui::NotFoundError, topic_name) }
                .then { |topic| Topic.new(topic) }
            end

            def partitions_count(topic_name, cached: true)
              topic(topic_name, cached: cached).partition_count
            end
          end
        end
      end
    end
  end
end
