# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
