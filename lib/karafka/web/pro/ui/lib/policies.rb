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
          # All code needed to support the search functionality
          module Policies
            class << self
              # Validates that the UI policies config is correct
              #
              # @param config [Karafka::Core::Configurable::Node] web config
              def post_setup(config)
                Policies::Contracts::Config.new.validate!(config.to_h)
              end
            end
          end
        end
      end
    end
  end
end
