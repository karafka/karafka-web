# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener for listening on connections related events like polling, etc
          class Connections < Base
            # Set first poll time before we start fetching so we always have a poll time
            # and we don't have to worry about it being always available
            # @param event [Karafka::Core::Monitoring::Event]
            def on_connection_listener_before_fetch_loop(event)
              on_connection_listener_fetch_loop_received(event)
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
                sampler.subscription_groups[sg_id] = {
                  polled_at: monotonic_now
                }
              end
            end
          end
        end
      end
    end
  end
end
