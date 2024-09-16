# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
