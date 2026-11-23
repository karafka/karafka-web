# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener for listening on connections related events like polling, etc
          class Connections < Base
            # Initializes the subscription group with defaults so it is always available
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_before_fetch_loop(event)
              subscription_group = event[:subscription_group]
              sg_id = subscription_group.id
              kafka_config = subscription_group.kafka
              # Use false to explicitly indicate static membership is not configured
              # vs nil which could be ambiguous
              instance_id = kafka_config[:"group.instance.id"] || false
              # Track max.poll.interval.ms to help users monitor how close they are to the limit
              # Value is in milliseconds, consistent with poll_age and other age metrics
              poll_interval = kafka_config[:"max.poll.interval.ms"] || Sampler::DEFAULT_POLL_INTERVAL_MS

              track do |sampler|
                # This will initialize the hash upon first request
                sg = sampler.subscription_groups[sg_id]
                sg[:instance_id] = instance_id
                sg[:poll_interval] = poll_interval
              end
            end

            # When fetch loop is done it means this subscription group is no longer active and we
            # should stop reporting. The listener was stopped.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_after_fetch_loop(event)
              subscription_group = event[:subscription_group]
              sg_id = subscription_group.id
              cg_id = group_id_of(subscription_group)

              track do |sampler|
                sampler.consumer_groups[cg_id][:subscription_groups].delete(sg_id)
                sampler.subscription_groups.delete(sg_id)
              end
            end

            # Tracks the moment a poll happened on a given subscription group and its member id
            #
            # The cluster assigns the member id when the consumer joins the group and may assign a
            # new one when it rejoins, so we read it until it is known and again after each
            # rebalance. This runs in the listener thread that owns the consumer.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_fetch_loop_received(event)
              sg_id = event[:subscription_group].id
              client = event[:client]

              track do |sampler|
                sg = sampler.subscription_groups[sg_id]
                sg[:polled_at] = monotonic_now
                sg[:member_id] = read_member_id(client) if sg[:member_id].empty?
              end
            end

            # Marks the member id of the subscription group to be read again on the next poll, as
            # it may have changed when the consumer rejoined the group
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_rebalance_partitions_assigned(event)
              sg_id = event[:subscription_group_id]

              track do |sampler|
                next unless sampler.subscription_groups.key?(sg_id)

                sampler.subscription_groups[sg_id][:member_id] = ""
              end
            end

            private

            # @param client [Karafka::Connection::ConsumerGroups::Client]
            # @return [String] group member id or an empty string when the consumer did not join the
            #   group yet
            def read_member_id(client)
              client.wrapped_kafka&.member_id || ""
            end
          end
        end
      end
    end
  end
end
