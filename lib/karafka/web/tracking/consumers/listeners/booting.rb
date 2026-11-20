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
                "karafka.web.tracking.scheduler"
              )
            end

            # Adds ppid to nodes and replaces the Web producer if it is the pre-fork app producer
            #
            # The node closes the pre-fork app producer and builds a new one, so a Web producer
            # that is (a variant of) the old one has to follow. The default Web producer rebuilds
            # itself after fork, and a dedicated one (e.g. non-idempotent) must stay as configured.
            #
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_swarm_node_after_fork(_event)
              ::Karafka::Process.tags.add(:node_ppid, "ppid:#{::Process.ppid}")

              producer = ::Karafka::Web.config.producer

              return if producer.is_a?(::Karafka::Web::Producer)
              return unless producer.status.closed?

              ::Karafka::Web.config.producer = ::Karafka::App.config.producer
            end
          end
        end
      end
    end
  end
end
