# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Namespace for controllers related to working with topics in the
            # context of consumers processes
            module Topics
              # Base controller for all the topic related management stuff
              class BaseController < ConsumersController
                private

                # Finds all the needed details and if not found raises a not found.
                # This prevents most cases where something would change between visiting the pages
                # and dispatching no longer valid data.
                #
                # @param process_id [String]
                # @param subscription_group_id [String]
                # @param topic [String]
                def bootstrap!(
                  process_id,
                  subscription_group_id,
                  topic
                )
                  subscriptions(process_id)

                  @subscription_group_id = subscription_group_id
                  @topic = topic
                  @consumer_group = nil
                  @subscription_group = nil
                  @topic_stats = nil

                  # Looks for the appropriate details about given topic in the
                  # current process data. Since we operate in the context of the given process,
                  # it must have those details. If not it means that assignment most likely have
                  # changed and it is no longer valid anyhow.
                  @process.consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      next unless subscription_group.id == @subscription_group_id

                      @subscription_group = subscription_group
                      @consumer_group = consumer_group

                      subscription_group.topics.each do |s_topic|
                        next unless s_topic.name == @topic

                        @topic_stats = s_topic
                      end
                    end
                  end

                  @subscription_group || raise(Karafka::Web::Errors::Ui::NotFoundError)
                  @topic_stats || raise(Karafka::Web::Errors::Ui::NotFoundError)

                  routing_topics = Karafka::App.routes.flat_map(&:topics).flat_map(&:to_a)

                  @routing_topic = routing_topics.find do |r_topic|
                    r_topic.subscription_group.id == @subscription_group.id &&
                      r_topic.name == @topic
                  end

                  # May not be found when not all routing is available. In such cases we assume
                  # that topic is not LRJ and it's up to the end user to handle this correctly.
                  @topic_lrj = @routing_topic&.long_running_job?
                end
              end
            end
          end
        end
      end
    end
  end
end
