# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener used to attach tags to consumers for Web-UI usage. Those tags will be picked
          # up by another listener
          #
          # @note We cannot attach here certain the ActiveJob consumer tags and they need to be
          #   in Karafka itself (mainly the per AJ job tag) because from the outside consumer
          #   perspective we have a single consumption that can run multiple different AJ jobs
          #
          # @note We can assign tags here and the order of tracking listeners does not matter,
          #   because tags state for consumers is materialized in the moment of reporting.
          class Tags < Base
            # @param event [Karafka::Core::Monitoring::Event]
            def on_consumer_consume(event)
              consumer = event.payload[:caller]

              tag_active_job(consumer)
              tag_attempt(consumer)

              return unless Karafka.pro?

              tag_virtual_partitions(consumer)
              tag_long_running_job(consumer)
            end

            private

            # Adds ActiveJob consumer related tags
            #
            # @param consumer [Karafka::BaseConsumer]
            def tag_active_job(consumer)
              return unless consumer.topic.active_job?

              consumer.tags.add(:active_job, :active_job)
            end

            # Adds attempts counter if this is not the first attempt. Not the first means, there
            # was an error and we are re-processing.
            #
            # @param consumer [Karafka::BaseConsumer]
            def tag_attempt(consumer)
              attempt = consumer.coordinator.pause_tracker.attempt

              if attempt > 1
                consumer.tags.add(:attempt, "attempt: #{attempt}")
              else
                consumer.tags.delete(:attempt)
              end
            end

            # Tags virtual partitioned consumers and adds extra info if operates in a collapsed
            # mode
            #
            # @param consumer [Karafka::BaseConsumer]
            def tag_virtual_partitions(consumer)
              return unless consumer.topic.virtual_partitions?

              consumer.tags.add(:virtual, :virtual)

              if consumer.collapsed?
                consumer.tags.add(:collapsed, :collapsed)
              else
                consumer.tags.delete(:collapsed)
              end
            end

            # Tags long running job consumer work
            #
            # @param consumer [Karafka::BaseConsumer]
            def tag_long_running_job(consumer)
              return unless consumer.topic.long_running_job?

              consumer.tags.add(:long_running_job, :long_running)
            end
          end
        end
      end
    end
  end
end
