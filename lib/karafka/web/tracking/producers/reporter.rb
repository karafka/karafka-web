# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        # Reports the collected data about the producer and sends it, so we can use it in the UI
        #
        # @note Producer reported does not have to operate with the `forced` dispatch mainly
        #   because there is no expectation on immediate status updates for producers and their
        #   dispatch flow is always periodic based.
        class Reporter < Tracking::Reporter
          # This mutex is shared between tracker and samplers so there is no case where metrics
          # would be collected same time tracker reports
          MUTEX = Mutex.new

          def initialize
            super
            # If there are any errors right after we started sampling, dispatch them immediately
            @tracked_at = monotonic_now - 10_000
            @error_contract = Tracking::Contracts::Error.new
          end

          # Dispatches the current state from sampler to appropriate topics
          def report
            MUTEX.synchronize do
              return unless report?

              @tracked_at = monotonic_now

              # Report errors that occurred (if any)
              messages = sampler.errors.map do |error|
                @error_contract.validate!(error)

                {
                  topic: Karafka::Web.config.topics.errors,
                  payload: error.to_json,
                  # Always dispatch errors from the same process to the same partition
                  key: error[:process][:id]
                }
              end

              return if messages.empty?

              produce(messages)

              # Clear the sampler so it tracks new state changes without previous once impacting
              # the data
              sampler.clear
            end
          end

          private

          # @return [Boolean] Should we report or is it not yet time to do so
          def report?
            return false unless active?

            (monotonic_now - @tracked_at) >= ::Karafka::Web.config.tracking.interval
          end

          # @return [Object] sampler for the metrics
          def sampler
            @sampler ||= ::Karafka::Web.config.tracking.producers.sampler
          end

          # Produces messages to Kafka.
          #
          # @param messages [Array<Hash>]
          #
          # @note We pick either sync or async dependent on number of messages. The trick here is,
          #   that we do not want to end up overloading the internal queue with messages in case
          #   someone has a lot of errors from processing or other errors. Producing sync will wait
          #   for the delivery, hence will slow things down a little bit. On the other hand during
          #   normal operations we should not have that many messages to dispatch and it should not
          #   slowdown any processing.
          def produce(messages)
            if messages.count >= ::Karafka::Web.config.tracking.producers.sync_threshold
              ::Karafka::Web.producer.produce_many_sync(messages)
            else
              ::Karafka::Web.producer.produce_many_async(messages)
            end
          # Since we run this in a background thread, there may be a case upon shutdown, where the
          # producer is closed right before a potential dispatch. It is not worth dealing with this
          # and we can just safely ignore this
          rescue WaterDrop::Errors::ProducerClosedError
            nil
          rescue StandardError => e
            p '------------------------------------------------'
            p e
          end
        end
      end
    end
  end
end
