# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single topic data representation model
        class Topic < Lib::HashProxy
          class << self
            # @return [Array<Broker>] all topics in the cluster
            def all
              ClusterInfo.fetch.topics.map do |topic|
                new(topic)
              end
            end

            # Finds requested topic
            #
            # @param topic_name [String] name of the topic
            # @return [Topic]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError]
            def find(topic_name)
              found = all.find { |topic| topic.topic_name == topic_name }

              return found if found

              raise(::Karafka::Web::Errors::Ui::NotFoundError, topic_name)
            end
          end

          # @return [Array<Partition>] All topic partitions data
          def partitions
            super.map do |partition_id, partition_hash|
              partition_hash[:partition_id] = partition_id

              Partition.new(partition_hash)
            end
          end

          # @return [Array<Karafka::Admin::Configs::Config>] all topic configs
          def configs
            @configs ||= ::Karafka::Admin::Configs.describe(
              ::Karafka::Admin::Configs::Resource.new(
                type: :topic,
                name: topic_name
              )
            ).first.configs.dup
          end
        end
      end
    end
  end
end
