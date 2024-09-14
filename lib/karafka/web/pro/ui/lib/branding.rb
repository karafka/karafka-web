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
      module Ui
        module Lib
          # Namespace for UI branding related stuff
          # Branding allows users to set an extra label and notice per env so users won't be
          # confused by dev vs prod etc.
          module Branding
            class << self
              # Validates that the UI branding config is correct
              #
              # @param config [Karafka::Core::Configurable::Node] web config
              def post_setup(config)
                Branding::Contracts::Config.new.validate!(config.to_h)
              end
            end
          end
        end
      end
    end
  end
end
