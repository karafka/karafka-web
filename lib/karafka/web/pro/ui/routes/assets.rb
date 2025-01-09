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
        # Namespace for Ui related sub-routes
        module Routes
          # Manages the assets related routes
          class Assets < Base
            route do |r|
              # Serve current version specific assets to prevent users from fetching old assets
              # after upgrade
              r.on 'assets', Karafka::Web::VERSION do
                r.public
              end
            end
          end
        end
      end
    end
  end
end
