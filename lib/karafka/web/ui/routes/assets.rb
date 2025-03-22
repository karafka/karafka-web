# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for Ui related sub-routes
      module Routes
        # Manages the assets related routes
        class Assets < Base
          route do |r|
            # Serves current version specific assets to prevent users from fetching old assets
            # after upgrade.
            r.on 'assets', Karafka::Web::VERSION do
              custom_css = Karafka::Web.config.ui.custom.css

              # If there are custom css styles and js inserted via the config we should display
              # them. They can be either files or just content.
              if custom_css
                r.get('stylesheets/custom.css') do
                  response['Content-Type'] = 'text/css'
                  response['Cache-Control'] = 'max-age=31536000, immutable'

                  if File.exist?(custom_css) && File.file?(custom_css)
                    File.read(custom_css)
                  else
                    custom_css
                  end
                end
              end

              custom_js = Karafka::Web.config.ui.custom.js

              if custom_js
                r.get('javascripts/custom.js') do
                  response['Content-Type'] = 'application/javascript'
                  response['Cache-Control'] = 'max-age=31536000, immutable'

                  if File.exist?(custom_js) && File.file?(custom_js)
                    File.read(custom_js)
                  else
                    custom_js
                  end
                end
              end

              r.public
            end
          end
        end
      end
    end
  end
end
