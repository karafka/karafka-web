# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener that is used to collect metrics related to work processing
          class Processing < Base
            # Collect time metrics about worker work execution time
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_worker_processed(event)
              track do |sampler|
                sampler.windows.m1[:processed_total_time] << event[:time]
              end
            end

            # We do not track idle jobs here because they are internal and not user-facing
            %i[
              consume
              revoked
              shutdown
              tick
              eofed
            ].each do |action|
              # Tracks the job that is going to be scheduled so we can also display pending jobs
              class_eval <<~RUBY, __FILE__, __LINE__ + 1
                # @param event [Karafka::Core::Monitoring::Event]
                def on_consumer_before_schedule_#{action}(event)
                  consumer = event.payload[:caller]
                  jid = job_id(consumer, '#{action}')
                  job_details = job_details(consumer, '#{action}')
                  job_details[:status] = 'pending'

                  track do |sampler|
                    sampler.jobs[jid] = job_details
                  end
                end
              RUBY
            end

            # Counts work execution and processing states in consumer instances
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_consumer_consume(event)
              consumer = event.payload[:caller]
              messages_count = consumer.messages.size
              jid = job_id(consumer, 'consume')
              job_details = job_details(consumer, 'consume')

              track do |sampler|
                # We count batches and messages prior to the execution, so they are tracked even
                # if error occurs, etc.
                sampler.counters[:jobs] += 1
                sampler.counters[:batches] += 1
                sampler.counters[:messages] += messages_count
                sampler.jobs[jid] = job_details
              end
            end

            # Collect info about consumption event that occurred and its metrics
            # Removes the job from running jobs
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_consumer_consumed(event)
              consumer = event.payload[:caller]
              jid = job_id(consumer, 'consume')

              track do |sampler|
                sampler.jobs.delete(jid)
              end
            end

            # Removes failed job from active jobs
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_error_occurred(event)
              track do |sampler|
                type = case event[:type]
                       when 'consumer.consume.error'
                         'consume'
                       when 'consumer.revoked.error'
                         'revoked'
                       when 'consumer.shutdown.error'
                         'shutdown'
                       when 'consumer.tick.error'
                         'tick'
                       when 'consumer.eofed.error'
                         'eofed'
                       # This is not a user facing execution flow, but internal system one
                       # that is why it will not be reported as a separate job for the UI
                       when 'consumer.idle.error'
                         false
                       else
                         false
                       end

                # job reference only exists for consumer work related operations.
                # Only for them we need to deregister the job reference.
                # This also refers only to consumer work that runs user operations.
                return unless type

                sampler.jobs.delete(
                  job_id(event[:caller], type)
                )
              end
            end

            # Consume has a bit different reporting flow than other jobs because it bumps certain
            # counters that other jobs do not. This is why it is defined above separately
            [
              [:revoke, :revoked, 'revoked'],
              [:shutting_down, :shutdown, 'shutdown'],
              [:tick, :ticked, 'tick'],
              [:eof, :eofed, 'eofed']
            ].each do |pre, post, action|
              class_eval <<~METHOD, __FILE__, __LINE__ + 1
                # Stores this job details
                #
                # @param event [Karafka::Core::Monitoring::Event]
                def on_consumer_#{pre}(event)
                  consumer = event.payload[:caller]
                  jid = job_id(consumer, '#{action}')
                  job_details = job_details(consumer, '#{action}')

                  track do |sampler|
                    sampler.counters[:jobs] += 1
                    sampler.jobs[jid] = job_details
                  end
                end

                # Removes the job from running jobs
                #
                # @param event [Karafka::Core::Monitoring::Event]
                def on_consumer_#{post}(event)
                  consumer = event.payload[:caller]
                  jid = job_id(consumer, '#{action}')

                  track do |sampler|
                    sampler.jobs.delete(jid)
                  end
                end
              METHOD
            end

            private

            # Generates a job id that we can use to track jobs in an unique way
            #
            # @param consumer [::Karafka::BaseConsumer] consumer instance
            # @param type [String] job type
            def job_id(consumer, type)
              "#{consumer.id}-#{type}"
            end

            # Gets consumer details for job tracking
            #
            # @param consumer [::Karafka::BaseConsumer] consumer instance
            # @param type [String] job type
            # @note Be aware, that non consumption jobs may not have any messages (empty) in them
            #   when certain filters or features are applied. Please refer to the Karafka docs for
            #   more details.
            def job_details(consumer, type)
              {
                updated_at: float_now,
                topic: consumer.topic.name,
                partition: consumer.partition,
                first_offset: consumer.messages.metadata.first_offset,
                last_offset: consumer.messages.metadata.last_offset,
                processing_lag: consumer.messages.metadata.processing_lag,
                consumption_lag: consumer.messages.metadata.consumption_lag,
                # Committed offset may be -1 when there is no committed offset. This can happen in
                # case of ticking that started before any consumption job happened
                committed_offset: consumer.coordinator.seek_offset.to_i - 1,
                # In theory this is redundant because we have first and last offset, but it is
                # needed because VPs do not have linear count. For VPs first and last offset
                # will be further away than the total messages count for a particular VP
                messages: consumer.messages.size,
                consumer: consumer.class.to_s,
                consumer_group: consumer.topic.consumer_group.id,
                type: type,
                tags: consumer.tags,
                status: 'running'
              }
            end
          end
        end
      end
    end
  end
end
