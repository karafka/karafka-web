# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      # Namespace for things related to consumers commanding (management)
      #
      # This feature allows for basic of consumers. They can be stopped, moved to quiet or traced
      # via the Web UI
      module Commanding
        class << self
          # Subscribes with the commanding manager when commanding is enabled
          #
          # @param config [Karafka::Core::Configurable::Node] web config
          def post_setup(config)
            # We do not use manager if commanding is not suppose to work at all
            return unless config.commanding.active

            Commanding::Contracts::Config.new.validate!(config.to_h)

            ::Karafka.monitor.subscribe(
              Commanding::Manager.instance
            )
          end
        end
      end
    end
  end
end
