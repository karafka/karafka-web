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
        module Controllers
          module Consumers
            # Displays processes with details + ability to manage
            class ControlsController < ConsumersController
              self.sortable_attributes = %w[
                id
                status
                started_at
                memory_usage
                lag_hybrid
              ].freeze

              # Displays list of consumer processes + options to manage them
              def index
                super

                render
              end
            end
          end
        end
      end
    end
  end
end
