# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
