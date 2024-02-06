# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Triggers reporters to report in an async mode in a separate thread
      # We report this way to prevent any potential dead-locks in cases we would be emitting
      # statistics during transactions.
      #
      # We should never use the notifications thread for sensitive IO bound operations.
      class Scheduler
        include ::Karafka::Helpers::Async

        private

        # Reports the process state once in a while
        def call
          # We won't track more often anyhow but want to try frequently not to miss a window
          # We need to convert the sleep interval into seconds for sleep
          sleep_time = ::Karafka::Web.config.tracking.interval.to_f / 1_000 / 10

          loop do
            # Not every reporter may be active at a given stage or in a context of a given process
            # We select only those that decided that they are active.
            reporters.select(&:active?).each(&:report)

            sleep(sleep_time)
          end
        end

        # @return [Array] consumers and producers reporters
        def reporters
          @reporters ||= [
            ::Karafka::Web.config.tracking.consumers.reporter,
            ::Karafka::Web.config.tracking.producers.reporter
          ].freeze
        end
      end
    end
  end
end
