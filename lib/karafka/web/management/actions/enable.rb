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
            extend_declaratives
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

            raise Web::Errors::KarafkaNotInitializedError, "Please initialize Karafka first"
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
                topic ::Karafka::Web.config.topics.consumers.reports.name do
                  active ::Karafka::Web.config.processing.active
                  # Since we materialize state in intervals, we can poll for half of this time
                  # without impacting the reporting responsiveness
                  max_wait_time ::Karafka::Web.config.processing.interval / 2
                  max_messages 200
                  consumer ::Karafka::Web::Processing::Consumer
                  # This needs to be true in order not to reload the consumer in dev. This consumer
                  # should not be affected by the end user development process
                  consumer_persistence true
                  deserializers(payload: payload_deserializer)
                  manual_offset_management true
                  # Start from the most recent data, do not materialize historical states
                  # This prevents us from dealing with cases, where client id would be changed and
                  # consumer group name would be renamed and we would start consuming all historical
                  initial_offset "latest"
                  # Increase backoff time on errors. Incompatible schema errors are not recoverable
                  # until rolling upgrade completes, so we use a longer max timeout to prevent
                  # spamming errors in logs. We set this ourselves so user settings do not impact
                  # frequency of retrying.
                  #
                  # Per-topic pause customization is a Karafka Pro feature (Granular Backoffs), so we
                  # only apply it when Pro is available; on OSS we fall back to the global pause
                  # defaults.
                  if ::Karafka.pro?
                    pause(
                      timeout: 5_000,
                      max_timeout: 60_000,
                      with_exponential_backoff: true
                    )
                  end
                  # We use the defaults + our config alterations that may not align with what
                  # user wants for his topics.
                  kafka kafka_config
                end

                # We define those three here without consumption, so Web understands how to
                # deserialize them when used / viewed
                topic ::Karafka::Web.config.topics.consumers.states.name do
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.consumers.metrics.name do
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.consumers.commands.name do
                  active false
                  deserializers(payload: payload_deserializer)
                end

                topic ::Karafka::Web.config.topics.errors.name do
                  active false
                  deserializers(payload: payload_deserializer)
                end
              end
            end
          end

          # Registers the Web UI topics in the standalone declaratives repository.
          #
          # They are all declared as `active false` on purpose. Web UI manages the creation and
          # configuration of its topics on its own (via `karafka-web install` / `karafka-web
          # migrate`), because it computes the replication factor at runtime based on the cluster
          # size and populates the initial states right after the topics are created. Declaring
          # them here (rather than relying on the legacy routing `config(...)` bridge) makes their
          # existence explicit in the new declaratives subsystem while keeping them out of the
          # generic `karafka declaratives` CLI management.
          def extend_declaratives
            topics = [
              ::Karafka::Web.config.topics.errors,
              ::Karafka::Web.config.topics.consumers.reports,
              ::Karafka::Web.config.topics.consumers.states,
              ::Karafka::Web.config.topics.consumers.metrics,
              ::Karafka::Web.config.topics.consumers.commands
            ]

            ::Karafka::App.declaratives.draw do
              topics.each do |web_topic|
                topic web_topic.name do
                  active false
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

            # Installs all the producer related listeners so that we track errors from every
            # producer and not only the default and the Web UI ones
            subscribe_to_producers

            # Installs all the UI related listeners for tracking errors from web processes
            # These listen on Karafka monitor to catch instrumented UI errors
            ::Karafka::Web.config.tracking.ui.listeners.each do |listener|
              ::Karafka.monitor.subscribe(listener)
            end
          end

          # Subscribes the producer tracking listeners to every WaterDrop producer.
          #
          # Historically we only instrumented `Karafka.producer` and `Karafka::Web.producer`, so
          # errors published by any other producer a user created (a secondary producer, a
          # transactional one, etc.) never reached the Web UI. WaterDrop's class-level monitor
          # announces every producer as it is configured, so we hook into it and attach our
          # listeners to each producer's own monitor. Producers that already exist by the time Web
          # is enabled are not announced again, so we also attach to them explicitly.
          def subscribe_to_producers
            # Initialize the bookkeeping before wiring the global monitor so a producer configured
            # from another thread cannot race the lazy memoization below
            tracked_producer_monitors
            producers_tracking_mutex

            # Any producer configured from now on is announced here; attach to it as it appears
            ::WaterDrop.monitor.subscribe("producer.configured") do |event|
              subscribe_producer_listeners(event[:producer])
            end

            # Producers that already exist will not be re-announced, so attach to them directly.
            # `Karafka::Web.producer` is either the default producer or a variant of it, so it
            # shares the default producer's monitor; the per-monitor guard keeps us from
            # subscribing the same monitor twice.
            subscribe_producer_listeners(::Karafka.producer)
            subscribe_producer_listeners(::Karafka::Web.producer)
          end

          # Subscribes all producer tracking listeners to a single producer's monitor, at most once
          # per monitor. Producers can be created from multiple threads, so the bookkeeping is
          # guarded by a mutex.
          #
          # @param producer [WaterDrop::Producer, WaterDrop::Producer::Variant] producer whose
          #   monitor we want to instrument
          def subscribe_producer_listeners(producer)
            monitor = producer.monitor

            producers_tracking_mutex.synchronize do
              # A variant shares its parent producer's monitor and the default and Web producers
              # often are the same monitor, so guard on the monitor to never double-subscribe.
              return unless tracked_producer_monitors.add?(monitor.object_id)
            end

            ::Karafka::Web.config.tracking.producers.listeners.each do |listener|
              monitor.subscribe(listener)
            end
          end

          # @return [Set<Integer>] object ids of producer monitors we have already instrumented
          def tracked_producer_monitors
            @tracked_producer_monitors ||= Set.new
          end

          # @return [Mutex] mutex guarding the tracked producer monitors bookkeeping
          def producers_tracking_mutex
            @producers_tracking_mutex ||= Mutex.new
          end

          # In most cases we want to close the producer if possible.
          # While we cannot do it easily in user processes and we should rely on WaterDrop
          # finalization logic, we can do it in `karafka server` on terminate
          #
          # In other places, this producer anyhow should not be used.
          def subscribe_to_close_web_producer
            ::Karafka::App.monitor.subscribe("app.terminated") do
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
