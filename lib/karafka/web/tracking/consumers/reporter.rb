# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        # Reports the collected data about the process and sends it, so we can use it in the UI
        class Reporter
          include ::Karafka::Core::Helpers::Time
          include ::Karafka::Helpers::Async

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
            @report_contract = Consumers::Contracts::Report.new
            @error_contract = Tracking::Contracts::Error.new
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
              # Start background thread only when needed
              # This prevents us from starting it too early or for non-consumer processes where
              # Karafka is being included
              async_call unless @running

              return unless report?(forced)

              @tracked_at = monotonic_now

              report = sampler.to_report

              @report_contract.validate!(report)

              process_name = report[:process][:name]

              # Report consumers statuses
              messages = [
                {
                  topic: ::Karafka::Web.config.topics.consumers.reports,
                  payload: Zlib::Deflate.deflate(report.to_json),
                  key: process_name,
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
                  key: process_name,
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

          # Reports the process state once in a while
          def call
            @running = true

            # We won't track more often anyhow but want to try frequently not to miss a window
            # We need to convert the sleep interval into seconds for sleep
            sleep_time = ::Karafka::Web.config.tracking.interval.to_f / 1_000 / 10

            loop do
              report

              sleep(sleep_time)
            end
          end

          # @param forced [Boolean] is this report forced. Forced means that as long as we can
          #   flush we will flush
          # @return [Boolean] Should we report or is it not yet time to do so
          def report?(forced)
            # We never report in initializing phase because things are not yet fully configured
            return false if ::Karafka::App.initializing?
            # We never report in the initialized because server is not yet ready until Karafka is
            # fully running and some of the things like listeners are not yet available
            return false if ::Karafka::App.initialized?

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
