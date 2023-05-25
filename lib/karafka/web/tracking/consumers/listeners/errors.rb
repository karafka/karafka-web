# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener related to tracking errors, DLQs, and retries metrics for the Web UI
          class Errors < Base
            include Tracking::Helpers::ErrorInfo

            # Collects errors info and counts errors
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_error_occurred(event)
              track do |sampler|
                # Collect extra info if it was a consumer related error.
                # Those come from user code
                details = if event[:caller].is_a?(Karafka::BaseConsumer)
                            extract_consumer_info(event[:caller])
                          else
                            {}
                          end

                error_class, error_message, backtrace = extract_error_info(event[:error])

                sampler.errors << {
                  type: event[:type],
                  error_class: error_class,
                  error_message: error_message,
                  backtrace: backtrace,
                  details: details,
                  occurred_at: float_now,
                  process: sampler.to_report[:process].slice(:name, :tags)
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
                partition: consumer.partition,
                first_offset: consumer.messages.metadata.first_offset,
                last_offset: consumer.messages.metadata.last_offset,
                committed_offset: consumer.coordinator.seek_offset - 1,
                consumer: consumer.class.to_s,
                tags: consumer.tags
              }
            end
          end
        end
      end
    end
  end
end
