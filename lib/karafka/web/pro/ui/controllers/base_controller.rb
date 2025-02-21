# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for Pro controllers
        module Controllers
          # Base Pro controller
          class BaseController < Web::Ui::Controllers::BaseController
            private

            # @return [Karafka::Web::Pro::Ui::Lib::Features] features fetcher
            def features
              Lib::Features
            end
          end
        end
      end
    end
  end
end
