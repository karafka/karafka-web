# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        # Reports the collected data about the process and sends it, so we can use it in the UI
        class Reporter < Tracking::Reporter
          # This mutex is shared between tracker and samplers so there is no case where metrics
          # would be collected same time tracker reports
          MUTEX = Mutex.new

          def initialize
            super
            # Move back so first report is dispatched fast to indicate, that the process is alive
            @tracked_at = monotonic_now - 10_000
            @report_contract = Consumers::Contracts::Report.new
            @error_contract = Tracking::Contracts::Error.new
          end

          # We never report in initializing phase because things are not yet fully configured
          # We never report in the initialized because server is not yet ready until Karafka is
          # fully running and some of the things like listeners are not yet available
          #
          # This method will also be `false` in case we are not running in `karafka server` or
          # in embedding, because in those cases Karafka does not go beyond the `initialized` phase
          #
          # @return [Boolean] are we able to report consumer state
          def active?
            # If we do not have a producer that we could use to report or it was closed, we cannot
            # and should not report
            return false unless super
            return false if ::Karafka::App.initializing?
            return false if ::Karafka::App.initialized?

            true
          end

          # Dispatches the current state from sampler to appropriate topics
          #
          # @param forced [Boolean] should we report bypassing the time frequency or should we
          #   report only in case we would not send the report for long enough time.
          def report(forced: false)
            # Do not even mutex if not needed
            return unless report?(forced)

            # We run this sampling before the mutex so sampling does not stop things in case
            # other threads would need this mutex. This can take up to 25ms and we do not want to
            # block during this time
            sampler.sample

            MUTEX.synchronize do
              return unless report?(forced)

              @tracked_at = monotonic_now

              report = sampler.to_report

              @report_contract.validate!(report)

              process_id = report[:process][:id]

              # Report consumers statuses
              messages = [
                {
                  topic: ::Karafka::Web.config.topics.consumers.reports,
                  payload: Zlib::Deflate.deflate(report.to_json),
                  key: process_id,
                  partition: 0,
                  headers: { 'zlib' => 'true' }
                }
              ]

              # Report errors that occurred (if any)
              messages += sampler.errors.map do |error|
                @error_contract.validate!(error)

                {
                  topic: Karafka::Web.config.topics.errors,
                  payload: Zlib::Deflate.deflate(error.to_json),
                  # Always dispatch errors from the same process to the same partition
                  key: process_id,
                  headers: { 'zlib' => 'true' }
                }
              end

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
            return false unless active?
            return true if forced

            (monotonic_now - @tracked_at) >= ::Karafka::Web.config.tracking.interval
          end

          # @return [Object] sampler for the metrics
          def sampler
            @sampler ||= ::Karafka::Web.config.tracking.consumers.sampler
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
            if messages.count >= sync_threshold
              ::Karafka::Web.producer.produce_many_sync(messages)
            else
              ::Karafka::Web.producer.produce_many_async(messages)
            end
          # Since we run this in a background thread, there may be a case upon shutdown, where the
          # producer is closed right before a potential dispatch. It is not worth dealing with this
          # and we can just safely ignore this
          rescue WaterDrop::Errors::ProducerClosedError
            nil
          end

          # @return [Integer] min number of messages when we switch to sync flushing to slow things
          def sync_threshold
            @sync_threshold ||= ::Karafka::Web.config.tracking.consumers.sync_threshold
          end
        end
      end
    end
  end
end
