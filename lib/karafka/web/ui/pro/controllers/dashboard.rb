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
          # Main Karafka Pro Web-Ui dashboard controller
          class Dashboard < Ui::Controllers::Base
            # View with statistics dashboard details
            def index
              @current_state = Models::ConsumersState.current!
              @counters = Models::Counters.new(@current_state)
              historicals = Models::Historicals.new(@current_state)
              # Load only historicals for the selected range
              @charts = Models::Charts.new(historicals, @params.current_range)

              respond
            end
          end
        end
      end
    end
  end
end
