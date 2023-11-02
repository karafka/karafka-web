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

          @flush_interval = ::Karafka::Web.config.processing.interval

          @schema_manager = Consumers::SchemaManager.new
          @state_aggregator = Consumers::Aggregators::State.new(@schema_manager)
          @state_contract = Consumers::Contracts::State.new

          @metrics_aggregator = Consumers::Aggregators::Metrics.new
          @metrics_contract = Consumers::Contracts::Metrics.new

          # We set this that way so we report with first batch and so we report as fast as possible
          @flushed_at = monotonic_now - @flush_interval
          @established = false
        end

        # Aggregates consumers state into a single current state representation
        def consume
          consumers_messages = messages.select { |message| message.payload[:type] == 'consumer' }

          # If there is even one incompatible message, we need to stop
          consumers_messages.each do |message|
            case @schema_manager.call(message)
            when :current
              true
            when :newer
              @schema_manager.invalidate!

              dispatch

              raise ::Karafka::Web::Errors::Processing::IncompatibleSchemaError
            # Older reports mean someone is in the middle of upgrade. Schema change related
            # upgrades always should happen without a rolling-upgrade, hence we can reject those
            # requests without significant or any impact on data quality but without having to
            # worry about backwards compatibility. Errors are tracked independently, so it should
            # not be a problem.
            when :older
              next
            else
              raise ::Karafka::Errors::UnsupportedCaseError
            end

            # We need to run the aggregations on each message in order to compensate for
            # potential lags.
            @state_aggregator.add(message.payload, message.offset)
            @metrics_aggregator.add_report(message.payload)
            @metrics_aggregator.add_stats(@state_aggregator.stats)
            # Indicates that we had at least one report we used to enrich data
            # If there were no state changes, there is no reason to flush data. This can occur
            # when we had some messages but we skipped them for any reason on a first run
            @established = true

            # Optimize memory usage in pro
            message.clean! if Karafka.pro?
          end

          return unless periodic_flush?

          dispatch

          mark_as_consumed(messages.last)
        end

        # Flush final state on shutdown
        def shutdown
          dispatch
        end

        private

        # Flushes the state of the Web-UI to the DB
        def dispatch
          return unless @established

          materialize
          validate!
          flush
        end

        # @return [Boolean] is it time to persist the new current state
        def periodic_flush?
          (monotonic_now - @flushed_at) > @flush_interval
        end

        # Materializes the current state and metrics for flushing
        def materialize
          @state = @state_aggregator.to_h
          @metrics = @metrics_aggregator.to_h
        end

        # Ensures that the aggregated data complies with our schema expectation.
        # If you ever get to this place, this is probably a bug and you should report it.
        def validate!
          @state_contract.validate!(@state)
          @metrics_contract.validate!(@metrics)
        end

        # Persists the new current state by flushing it to Kafka
        def flush
          @flushed_at = monotonic_now

          ::Karafka::Web.producer.produce_many_async(
            [
              {
                topic: Karafka::Web.config.topics.consumers.states,
                payload: Zlib::Deflate.deflate(@state.to_json),
                # This will ensure that the consumer states are compacted
                key: Karafka::Web.config.topics.consumers.states,
                partition: 0,
                headers: { 'zlib' => 'true' }
              },
              {
                topic: Karafka::Web.config.topics.consumers.metrics,
                payload: Zlib::Deflate.deflate(@metrics.to_json),
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
