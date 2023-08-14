# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # @note This runs on each process start that has `karafka.rb`. It needs to be executed
      #   also in the context of other processes types and not only karafka server, because it
      #   installs producers instrumentation and routing as well.
      class Enable < Base
        # Enables routing consumer group and subscribes Web-UI listeners
        def call
          extend_routing
          subscribe_to_monitor
        end

        private

        # Enables all the needed routes
        def extend_routing
          ::Karafka::App.routes.draw do
            web_deserializer = ::Karafka::Web::Deserializer.new

            consumer_group ::Karafka::Web.config.processing.consumer_group do
              # Topic we listen on to materialize the states
              topic ::Karafka::Web.config.topics.consumers.reports do
                config(active: false)
                active ::Karafka::Web.config.processing.active
                # Since we materialize state in intervals, we can poll for half of this time without
                # impacting the reporting responsiveness
                max_wait_time ::Karafka::Web.config.processing.interval / 2
                max_messages 1_000
                consumer ::Karafka::Web::Processing::Consumer
                # This needs to be true in order not to reload the consumer in dev. This consumer
                # should not be affected by the end user development process
                consumer_persistence true
                deserializer web_deserializer
                manual_offset_management true
                # Start from the most recent data, do not materialize historical states
                # This prevents us from dealing with cases, where client id would be changed and
                # consumer group name would be renamed and we would start consuming all historical
                initial_offset 'latest'
              end

              # We define those three here without consumption, so Web understands how to deserialize
              # them when used / viewed
              topic ::Karafka::Web.config.topics.consumers.states do
                config(active: false)
                active false
                deserializer web_deserializer
              end

              topic ::Karafka::Web.config.topics.consumers.metrics do
                config(active: false)
                active false
                deserializer web_deserializer
              end

              topic ::Karafka::Web.config.topics.errors do
                config(active: false)
                active false
                deserializer web_deserializer
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

          # Installs all the producer related listeners
          ::Karafka::Web.config.tracking.producers.listeners.each do |listener|
            ::Karafka.producer.monitor.subscribe(listener)
          end
        end
      end
    end
  end
end
