# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            module Partitions
              class BaseController < ConsumersController
                private

                # Finds all the needed details and if not found raises a not found.
                # This prevents most cases where something would change between visiting the edit
                # page and dispatching no longer valid data.
                #
                #
                # @param consumer_groups [Array<Karafka::Web::Ui::Models::ConsumerGroup>] current
                #   process consumer groups in use.
                def bootstrap!(consumer_groups, process_id, subscription_group_id, topic, partition_id)
                  subscriptions(process_id)

                  @subscription_group_id = subscription_group_id
                  @topic = topic
                  @partition_id = partition_id
                  @consumer_group = nil
                  @subscription_group = nil
                  @partition_stats = nil

                  consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      next unless subscription_group.id == @subscription_group_id

                      @subscription_group = subscription_group
                      @consumer_group = consumer_group

                      subscription_group.topics.each do |topic|
                        next unless topic.name == @topic

                        topic.partitions.each do |partition|
                          next unless @partition_id.to_s == partition.partition_id.to_s

                          @partition_stats = partition
                        end
                      end
                    end
                  end

                  routing_topics = Karafka::App.routes.flat_map(&:topics).flat_map(&:to_a)

                  @routing_topic = routing_topics.find do |topic|
                    topic.subscription_group.id == @subscription_group.id && topic.name == @topic
                  end

                  # May not be found when not all routing is available
                  @topic_lrj = @routing_topic && @routing_topic.long_running_job?
                  @subscription_group || raise(Karafka::Web::Errors::Ui::NotFoundError)
                  @partition_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)
                end
              end
            end
          end
        end
      end
    end
  end
end
