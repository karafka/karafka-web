# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
