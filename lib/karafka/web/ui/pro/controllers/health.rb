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
    module Ui
      module Pro
        module Controllers
          # Health state controller
          class Health < Ui::Controllers::Base
            # Displays the current system state
            def overview
              current_state = Models::ConsumersState.current!
              @stats = Models::Health.current(current_state)

              respond
            end

            def offsets
              # Same data as overview but presented differently
              overview

              respond
            end
          end
        end
      end
    end
  end
end
