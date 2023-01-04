# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener that triggers reporting on Karafka process status changes
          # Whenever the whole process status changes, we do not want to wait and want to report
          # as fast as possible, hence `report!`. This improves the user experience and since
          # status changes do not happen that often, we can handle few extra reports dispatches.
          class Status < Base
            # @param _event [Karafka::Core::Monitoring::Event]
            #
            # @note We do not use `#report!` here because this kicks in for each listener loop and
            #   those run the same time.
            def on_connection_listener_before_fetch_loop(_event)
              report
            end

            # Indicate as fast as possible that we've started moving to the quiet mode
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_app_quieting(_event)
              report!
            end

            # Indicate as fast as possible that we've reached the quiet mode
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_app_quiet(_event)
              report!
            end

            # Instrument on the fact that we're stopping
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_app_stopping(_event)
              # Make sure this is sent before shutdown
              report!
            end

            # Instrument on the fact that Karafka has stopped
            #
            # We do this actually before the process ends but we need to do this so the UI does not
            # have this "handling" stopping process.
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_app_stopped(_event)
              # Make sure this is sent before shutdown
              report!
            end
          end
        end
      end
    end
  end
end
