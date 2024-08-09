# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # @note This runs on each process start that has `karafka.rb`. It needs to be executed
        #   also in the context of other processes types and not only karafka server, because it
        #   installs producers instrumentation and routing as well.
        class Enable < Base
          # Enables routing consumer group and subscribes Web-UI listeners
          def call
            ensure_karafka_initialized!

            # Prevent double enabling
            return if ::Karafka::Web.config.enabled

            ::Karafka::Web.config.enabled = true

            extend_routing
            setup_tracking_activity

            # Do not subscribe monitors or do anything else if tracking is disabled
            return unless ::Karafka::Web.config.tracking.active

            subscribe_to_monitor
            subscribe_to_close_web_producer
          end

          private

          # We should not allow for enabling of Karafka Web when Karafka is not configured.
          # Karafka needs to be loaded and configured before Web can be configured because Web is
          # using Karafka configuration
          def ensure_karafka_initialized!
            return unless Karafka::App.config.internal.status.initializing?

            raise Web::Errors::KarafkaNotInitializedError, 'Please initialize Karafka first'
          end

          # Enables tracking if it was not explicitly disabled by the user
          def setup_tracking_activity
            return unless ::Karafka::Web.config.tracking.active.nil?

            ::Karafka::Web.config.tracking.active = true
          end

          # Enables all the needed routes
          def extend_routing
            kafka_config = ::Karafka::App.config.kafka.dup
            kafka_config.merge!(::Karafka::Web.config.processing.kafka)

            ::Karafka::App.routes.draw do
              payload_deserializer = ::Karafka::Web::Deserializer.new

              consumer_group ::Karafka::Web.config.group_id do
                # Topic we listen on to materialize the states
                topic ::Karafka::Web.config.topics.consumers.reports do
                  config(active: false)
                  active ::Karafka::Web.config.processing.active
                  # Since we materialize state in intervals, we can poll for half of this time
                  # without impacting the reporting responsiveness
                  max_wait_time ::Karafka::Web.config.processing.interval / 2
                  max_messages 1_000
                  consumer ::Karafka::Web::Processing::Consumer
                  # This needs to be true in order not to reload the consumer in dev. This consumer
                  # should not be affected by the end user development process
                  consumer_persistence true
                  deserializers(payload: payload_deserializer)
                  manual_offset_management true
                  # Start from the most recent data, do not materialize historical states
                  # This prevents us from dealing with cases, where client id would be changed and
                  # consumer group name would be renamed and we would start consuming all
                  # historical
                  initial_offset 'latest'
                  # We use the defaults + our config alterations that may not align with what
                  # user wants for his topics.
                  kafka kafka_config
                end

                # We define those three here without consumption, so Web understands how to
                # deserialize them when used / viewed
                topic ::Karafka::Web.config.topics.consumers.states do
                  config(active: false)
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.consumers.metrics do
                  config(active: false)
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.consumers.commands do
                  config(active: false)
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.errors do
                  config(active: false)
                  active false
                  deserializers(payload: payload_deserializer)
                end
              end
            end
          end

          # Subscribes with all needed listeners
          def subscribe_to_monitor
            # Installs all the consumer related listeners
            ::Karafka::Web.config.tracking.consumers.listeners.each do |listener|
              ::Karafka.monitor.subscribe(listener)
            end

            # Installs all the producer related listeners into Karafka default listener and
            # into Karafka::Web listener in case it would be different than the Karafka one
            ::Karafka::Web.config.tracking.producers.listeners.each do |listener|
              ::Karafka.producer.monitor.subscribe(listener)

              # Do not instrument twice in case only one default producer is used
              next if ::Karafka.producer == ::Karafka::Web.producer

              ::Karafka::Web.producer.monitor.subscribe(listener)
            end
          end

          # In most cases we want to close the producer if possible.
          # While we cannot do it easily in user processes and we should rely on WaterDrop
          # finalization logic, we can do it in `karafka server` on terminate
          #
          # In other places, this producer anyhow should not be used.
          def subscribe_to_close_web_producer
            ::Karafka::App.monitor.subscribe('app.terminated') do
              # If Web producer is the same as `Karafka.producer` it will do nothing as you can
              # call `#close` multiple times without side effects
              ::Karafka::Web.producer.close
            end
          end
        end
      end
    end
  end
end
