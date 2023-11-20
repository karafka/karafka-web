# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Tracks pausing and un-pausing of topics partitions for both user requested and
          # automatic events.
          class Pausing < Base
            # Indicate pause
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_consumer_consuming_pause(event)
              track do |sampler|
                sampler.pauses[pause_id(event)] = {
                  timeout: event[:timeout],
                  paused_till: monotonic_now + event[:timeout]
                }
              end
            end

            # Indicate pause ended
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_client_resume(event)
              track do |sampler|
                sampler.pauses.delete pause_id(event)
              end
            end

            private

            # @param event [Karafka::Core::Monitoring::Event]
            # @return [String] pause id built from consumer group and topic details
            def pause_id(event)
              topic = event[:topic]
              partition = event[:partition]
              subscription_group_id = event[:subscription_group].id

              [subscription_group_id, topic, partition].join('-')
            end
          end
        end
      end
    end
  end
end
