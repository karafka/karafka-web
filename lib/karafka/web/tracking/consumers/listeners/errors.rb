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
            SCHEMA_VERSION = "1.2.0"

            private_constant :SCHEMA_VERSION

            # Collects errors info and counts errors
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_error_occurred(event)
              # Error details come from two independent sources that we merge together:
              # - the caller: the user code context in which the error happened
              # - the error type: extra diagnostics some error types carry in the event payload
              details = extract_caller_details(event[:caller])
                .merge(extract_type_details(event))

              error_class, error_message, backtrace = extract_error_info(event[:error])

              track do |sampler|
                sampler.errors << {
                  schema_version: SCHEMA_VERSION,
                  id: SecureRandom.uuid,
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

            # Collects error details based on who reported the error, that is the user code
            # context in which it happened (consumer, client or listener).
            #
            # @param caller_ref [Object] object that reported the error
            # @return [Hash] hash with caller specific info for details of error
            def extract_caller_details(caller_ref)
              case caller_ref
              when Karafka::BaseConsumer
                extract_consumer_info(caller_ref)
              when Karafka::Connection::Client
                extract_client_info(caller_ref)
              when Karafka::Connection::Listener
                extract_listener_info(caller_ref)
              else
                {}
              end
            end

            # Collects error details based on the error type. Some error types carry extra
            # diagnostics in the event payload that do not come from the caller.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            # @return [Hash] hash with type specific info for details of error
            def extract_type_details(event)
              case event[:type]
              when "app.stopping.error"
                extract_forceful_shutdown_info(event)
              else
                {}
              end
            end

            # @param consumer [::Karafka::BaseConsumer]
            # @return [Hash] hash with consumer specific info for details of error
            def extract_consumer_info(consumer)
              {
                topic: consumer.topic.name,
                consumer_group: group_id_of(consumer.topic),
                subscription_group: consumer.topic.subscription_group.id,
                partition: consumer.partition,
                first_offset: consumer.messages.metadata.first_offset,
                last_offset: consumer.messages.metadata.last_offset,
                # We set it to -1000 if non-existent because after subtracting one, we will end up
                # with -1001, which is "N/A" offset position for all the offsets here
                committed_offset: (consumer.coordinator.seek_offset || -1_000) - 1,
                consumer: consumer.class.to_s,
                trace_id: Karafka.pro? ? consumer.errors_tracker.trace_id : nil,
                tags: consumer.tags
              }
            end

            # @param client [::Karafka::Connection::Client]
            # @return [Hash] hash with client specific info for details of error
            def extract_client_info(client)
              {
                consumer_group: group_id_of(client.subscription_group),
                subscription_group: client.subscription_group.id,
                name: client.name,
                id: client.id
              }
            end

            # @param listener [::Karafka::Connection::Listener]
            # @return [Hash] hash with listener specific info for details of error
            def extract_listener_info(listener)
              {
                consumer_group: group_id_of(listener.subscription_group),
                subscription_group: listener.subscription_group.id,
                id: listener.id
              }
            end

            # Extracts details about what was still blocking when Karafka forcefully terminated.
            # Karafka publishes the listeners that were still active and the jobs that were still
            # in the processing pipeline alongside the forceful shutdown error.
            #
            # The lists are formatted into readable strings so they render as regular rows in the
            # generic error details table (same presentation as every other error).
            #
            # @param event [Karafka::Core::Monitoring::Event]
            # @return [Hash] hash with forceful shutdown diagnostics for details of error
            def extract_forceful_shutdown_info(event)
              active_listeners = event[:active_listeners] || []
              alive_workers = event[:alive_workers] || []
              in_processing = event[:in_processing] || {}

              listeners = active_listeners.map do |listener|
                "#{listener.id} (#{listener.subscription_group.id})"
              end

              jobs = in_processing.flat_map do |group_id, group_jobs|
                group_jobs.map { |job| format_in_processing_job(group_id, job) }
              end

              # Only include the listener/job lists when there is something to show, so we do not
              # render empty rows in the error details table
              details = { alive_workers: alive_workers.size }
              details[:active_listeners] = listeners.join(", ") unless listeners.empty?
              details[:in_processing] = jobs.join("; ") unless jobs.empty?
              details
            end

            # Formats a single job that was still in processing into a readable description.
            #
            # @param group_id [String] subscription group id the job belongs to
            # @param job [Object] job that was still in the processing pipeline
            # @return [String] readable job description
            def format_in_processing_job(group_id, job)
              status = job.non_blocking? ? "non-blocking" : "blocking"
              job_type = job.class.name.split("::").last

              "#{job_type} #{job.executor.topic.name}/#{job.executor.partition} " \
                "(#{group_id}, #{status})"
            end
          end
        end
      end
    end
  end
end
