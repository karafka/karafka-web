# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Listener needed to start schedulers and other things that we need to collect and report
          # data. We do not want to start this when code is loaded because it may not be fork
          # compatible that way
          class Booting < Base
            # Starts (if needed) the Web UI tracking scheduler thread that periodically pings
            # reporters to report needed data (when it is time).
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_app_running(_event)
              ::Karafka::Web.config.tracking.scheduler.async_call(
                'karafka.web.tracking.scheduler'
              )
            end

            # Updates the web producer after fork if needed and adds ppid to nodes
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_swarm_node_after_fork(_event)
              ::Karafka::Process.tags.add(:node_ppid, "ppid:#{::Process.ppid}")

              return if Karafka::Web.config.producer == Karafka::App.config.producer

              Web.config.producer = Karafka::App.config.producer
            end
          end
        end
      end
    end
  end
end
