# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Policies
            # Extra configuration for pro UI
            class Config
              extend ::Karafka::Core::Configurable

              # Policies controller related to messages operations and visibility
              setting :messages, default: Policies::Messages.new

              # Policies controller related to all requests. It is a general one that is not
              # granular but can be used to block completely certain pieces of the UI from
              # accessing like explorer or any other as operates on the raw env level
              setting :requests, default: Policies::Requests.new

              configure
            end
          end
        end
      end
    end
  end
end
