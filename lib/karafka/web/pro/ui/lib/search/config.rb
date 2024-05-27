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
          module Search
            # Extra configuration for pro UI
            class Config
              extend ::Karafka::Core::Configurable

              # Matches for messages
              setting :matchers, default: [
                Matchers::RawPayloadIncludes,
                Matchers::RawKeyIncludes,
                Matchers::RawHeaderIncludes
              ]

              # How long should we at most search before stopping (in ms)
              # This prevents us from having a search that would basically hang the browser and
              # never finish
              setting :timeout, default: 30_000

              # Search limits as the search runs in Puma
              # Too big value will make the scan really slow
              # We do not put a max limit here because those values are used in a select in
              # the Web UI.
              setting :limits, default: [
                1_000,
                10_000,
                100_000
              ]

              configure
            end
          end
        end
      end
    end
  end
end
