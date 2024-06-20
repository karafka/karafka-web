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
              sg_id = event[:subscription_group].id

              track do |sampler|
                # This will initialize the hash upon first request
                sampler.subscription_groups[sg_id]
              end
            end

            # When fetch loop is done it means this subscription group is no longer active and we
            # should stop reporting. The listener was stopped.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_after_fetch_loop(event)
              subscription_group = event[:subscription_group]
              sg_id = subscription_group.id
              cg_id = subscription_group.consumer_group.id

              track do |sampler|
                sampler.consumer_groups[cg_id][:subscription_groups].delete(sg_id)
                sampler.subscription_groups.delete(sg_id)
              end
            end

            # Tracks the moment a poll happened on a given subscription group
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_fetch_loop_received(event)
              sg_id = event[:subscription_group].id

              track do |sampler|
                sampler.subscription_groups[sg_id][:polled_at] = monotonic_now
              end
            end
          end
        end
      end
    end
  end
end
