# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener related to tracking errors, DLQs, and retries metrics for the Web UI
          class Errors < Base
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
                  occurred_at: float_now
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
                partition: consumer.messages.metadata.partition,
                first_offset: consumer.messages.first.offset,
                last_offset: consumer.messages.last.offset,
                comitted_offset: consumer.coordinator.seek_offset - 1,
                consumer: consumer.class.to_s
              }
            end

            # Extracts the basic error info
            #
            # @param error [StandardError] error that occurred
            # @return [Array<String, String, String>] array with error name, message and backtrace
            def extract_error_info(error)
              error_message = error.message.to_s.dup
              error_message.force_encoding('utf-8')
              error_message.scrub!

              backtrace = (error.backtrace || [])

              app_root = "#{::Karafka.root}/"

              gem_home = if ENV.key?('GEM_HOME')
                           ENV['GEM_HOME']
                         else
                           File.expand_path(File.join(Karafka.gem_root.to_s, '../'))
                         end

              gem_home = "#{gem_home}/"

              backtrace.map! { |line| line.gsub(app_root, '') }
              backtrace.map! { |line| line.gsub(gem_home, '') }

              [
                error.class.name,
                error_message,
                backtrace.join("\n")
              ]
            end
          end
        end
      end
    end
  end
end
