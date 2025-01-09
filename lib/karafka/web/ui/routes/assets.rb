# frozen_string_literal: true

module Karafka
  module Web
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
