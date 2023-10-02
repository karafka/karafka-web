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
