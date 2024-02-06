# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        module Listeners
          class Booting < Base
            # Starts (if needed) the Web UI tracking scheduler thread that periodically pings
            # reporters to report needed data (when it is time).
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_producer_connected(_event)
              ::Karafka::Web.config.tracking.scheduler.async_call
            end
          end
        end
      end
    end
  end
end
