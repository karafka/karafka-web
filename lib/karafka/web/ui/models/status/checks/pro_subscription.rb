# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if Karafka Pro is enabled.
            #
            # This is an independent, warning-only check. Not having Pro is not
            # an error, but users should be aware that some features may not work
            # without it.
            class ProSubscription < Base
              independent!

              # Executes the Pro subscription check.
              #
              # @return [Status::Step] success if Pro is enabled, warning otherwise
              def call
                step(::Karafka.pro? ? :success : :warning)
              end
            end
          end
        end
      end
    end
  end
end
