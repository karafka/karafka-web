# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        # Reports the collected data about the process and sends it, so we can use it in the UI
        class Reporter
          include ::Karafka::Core::Helpers::Time

          # Minimum number of messages to produce to produce them in sync mode
          # This acts as a small back-off not to overload the system in case we would have
          # extremely big number of errors happening
          PRODUCE_SYNC_THRESHOLD = 25

          private_constant :PRODUCE_SYNC_THRESHOLD

          # This mutex is shared between tracker and samplers so there is no case where metrics
          # would be collected same time tracker reports
          MUTEX = Mutex.new

          def initialize
            # Move back so first report is dispatched fast to indicate, that the process is alive
            @tracked_at = monotonic_now - 10_000
            @error_contract = Tracking::Contracts::Error.new
          end

          # Dispatches the current state from sampler to appropriate topics
          #
          # @param forced [Boolean] should we report bypassing the time frequency or should we
          #   report only in case we would not send the report for long enough time.
          def report(forced: false)
            MUTEX.synchronize do
              return unless report?(forced)

              @tracked_at = monotonic_now

              # Report errors that occurred (if any)
              messages = sampler.errors.map do |error|
                @error_contract.validate!(error)

                {
                  topic: Karafka::Web.config.topics.errors,
                  payload: error.to_json,
                  # Always dispatch errors from the same process to the same partition
                  key: error[:process][:name]
                }
              end

              return if messages.empty?

              produce(messages)

              # Clear the sampler so it tracks new state changes without previous once impacting
              # the data
              sampler.clear
            end
          end

          # Reports bypassing frequency check. This can be used to report when state changes in the
          # process drastically. For example when process is stopping, we want to indicate this as
          # fast as possible in the UI, etc.
          def report!
            report(forced: true)
          end

          private

          # @param forced [Boolean] is this report forced. Forced means that as long as we can
          #   flush we will flush
          # @return [Boolean] Should we report or is it not yet time to do so
          def report?(forced)
            return false unless ::Karafka.producer.status.active?

            return true if forced

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
            if messages.count >= PRODUCE_SYNC_THRESHOLD
              ::Karafka.producer.produce_many_sync(messages)
            else
              ::Karafka.producer.produce_many_async(messages)
            end
          # Since we run this in a background thread, there may be a case upon shutdown, where the
          # producer is closed right before a potential dispatch. It is not worth dealing with this
          # and we can just safely ignore this
          rescue WaterDrop::Errors::ProducerClosedError
            nil
          end
        end
      end
    end
  end
end
