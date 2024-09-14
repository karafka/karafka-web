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
          module Branding
            # Extra configuration for pro UI branding feature
            class Config
              extend ::Karafka::Core::Configurable

              # Type of styling aligned with Daisy. info, error, warning, success, primary
              setting :type, default: :info

              # String label with env name. Will be displayed below the logo
              setting :label, default: false

              # Additional wide alert notice to highlight extra details. Nothing if false
              setting :notice, default: false

              configure
            end
          end
        end
      end
    end
  end
end
