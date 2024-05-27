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
      # Loader requires and loads all the pro components only when they are needed
      class Loader
        class << self
          # Loads all the Web UI pro components and configures them wherever it is expected
          # @param config [Karafka::Core::Configurable::Node] web config that we can alter with pro
          #   components
          def pre_setup_all(config)
            # Expand the config with commanding configuration
            config.instance_eval do
              setting(:commanding, default: Commanding::Config.config)
            end

            # Expand UI config with extra search capabilities settings
            config.ui.instance_eval do
              setting(:search, default: Ui::Lib::Search::Config.config)
            end
          end

          # Runs post setup features configuration operations
          #
          # @param config [Karafka::Core::Configurable::Node]
          def post_setup_all(config)
            Commanding.post_setup(config)
            Ui::Lib::Search.post_setup(config)
          end
        end
      end
    end
  end
end
