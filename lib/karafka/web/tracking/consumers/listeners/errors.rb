# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener related to tracking errors, DLQs, and retries metrics for the Web UI
          class Errors < Base
            include Tracking::Helpers::ErrorInfo

            # Schema used by consumers error reporting
            SCHEMA_VERSION = '1.1.0'

            private_constant :SCHEMA_VERSION

            # Collects errors info and counts errors
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_error_occurred(event)
              caller_ref = event[:caller]

              # Collect extra info if it was a consumer related error.
              # Those come from user code
              details = case caller_ref
                        when Karafka::BaseConsumer
                          extract_consumer_info(caller_ref)
                        when Karafka::Connection::Client
                          extract_client_info(caller_ref)
                        when Karafka::Connection::Listener
                          extract_listener_info(caller_ref)
                        else
                          {}
                        end

              error_class, error_message, backtrace = extract_error_info(event[:error])

              track do |sampler|
                sampler.errors << {
                  schema_version: SCHEMA_VERSION,
                  type: event[:type],
                  error_class: error_class,
                  error_message: error_message,
                  backtrace: backtrace,
                  details: details,
                  occurred_at: float_now,
                  process: sampler.to_report[:process].slice(:id, :tags)
                }

                sampler.counters[:errors] += 1
              end
            end

            # Count dead letter queue messages dispatches
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_dead_letter_queue_dispatched(_event)
              track do |sampler|
                sampler.counters[:dead] += 1
              end
            end

            # Count retries
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_consumer_consuming_retry(_event)
              track do |sampler|
                sampler.counters[:retries] += 1
              end
            end

            private

            # @param consumer [::Karafka::BaseConsumer]
            # @return [Hash] hash with consumer specific info for details of error
            def extract_consumer_info(consumer)
              {
                topic: consumer.topic.name,
                consumer_group: consumer.topic.consumer_group.id,
                subscription_group: consumer.topic.subscription_group.id,
                partition: consumer.partition,
                first_offset: consumer.messages.metadata.first_offset,
                last_offset: consumer.messages.metadata.last_offset,
                # We set it to -1000 if non-existent because after subtracting one, we will end up
                # with -1001, which is "N/A" offset position for all the offsets here
                committed_offset: (consumer.coordinator.seek_offset || -1_000) - 1,
                consumer: consumer.class.to_s,
                tags: consumer.tags
              }
            end

            # @param client [::Karafka::Connection::Client]
            # @return [Hash] hash with client specific info for details of error
            def extract_client_info(client)
              {
                consumer_group: client.subscription_group.consumer_group.id,
                subscription_group: client.subscription_group.id,
                name: client.name,
                id: client.id
              }
            end

            # @param listener [::Karafka::Connection::Listener]
            # @return [Hash] hash with listener specific info for details of error
            def extract_listener_info(listener)
              {
                consumer_group: listener.subscription_group.consumer_group.id,
                subscription_group: listener.subscription_group.id,
                id: listener.id
              }
            end
          end
        end
      end
    end
  end
end
