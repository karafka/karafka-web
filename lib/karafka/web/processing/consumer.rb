# frozen_string_literal: true

module Karafka
  module Web
    # Namespace used to encapsulate all the components needed to process the states data and
    # store it back in Kafka
    module Processing
      # Consumer used to squash and process statistics coming from particular processes, so this
      # data can be read and used. We consume this info overwriting the data we previously had
      # (if any)
      class Consumer < Karafka::BaseConsumer
        include ::Karafka::Core::Helpers::Time

        # @param args [Object] all the arguments `Karafka::BaseConsumer` accepts by default
        def initialize(*args)
          super

          @flush_interval = ::Karafka::Web.config.processing.interval / 1_000.to_f
          @state_aggregator = ::Karafka::Web::Processing::Consumers::StateAggregator.new
          @metrics_aggregator = ::Karafka::Web::Processing::Consumers::MetricsAggregator.new
          # We set this that way so we report with first batch and so we report in the development
          # mode. In the development mode, there is a new instance per each invocation, thus we need
          # to always initially report, so the web UI works well in the dev mode where consumer
          # instances are not long-living.
          @flushed_at = monotonic_now - @flush_interval
        end

        # Aggregates consumers state into a single current state representation
        def consume
          messages
            .select { |message| message.payload[:type] == 'consumer' }
            .each { |message| @state_aggregator.add(message.payload, message.offset) }
            .each { |message| @metrics_aggregator.add(message.payload) }

          # Only update the aggregated state after the states aggregation is done for a given
          # batch of reports
          @metrics_aggregator.update_aggregated_stats(@state_aggregator.stats)

          return unless periodic_flush?

          flush

          mark_as_consumed(messages.last)
        end

        # Flush final state on shutdown
        def shutdown
          flush if @state_aggregator
        end

        private

        # @return [Boolean] is it time to persist the new current state
        def periodic_flush?
          (monotonic_now - @flushed_at) > @flush_interval
        end

        # Persists the new current state by flushing it to Kafka
        def flush
          @flushed_at = monotonic_now

          producer.produce_many_async(
            [
              {
                topic: Karafka::Web.config.topics.consumers.states,
                payload: Zlib::Deflate.deflate(@state_aggregator.to_json),
                # This will ensure that the consumer states are compacted
                key: Karafka::Web.config.topics.consumers.states,
                partition: 0,
                headers: { 'zlib' => 'true' }
              },
              {
                topic: Karafka::Web.config.topics.consumers.metrics,
                payload: Zlib::Deflate.deflate(@metrics_aggregator.to_json),
                key: Karafka::Web.config.topics.consumers.metrics,
                partition: 0,
                headers: { 'zlib' => 'true' }
              }
            ]
          )
        end
      end
    end
  end
end
