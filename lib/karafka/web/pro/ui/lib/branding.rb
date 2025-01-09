# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
