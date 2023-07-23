# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Main Karafka Pro Web-Ui dashboard controller
        class Dashboard < Ui::Controllers::Base
          # View with statistics dashboard details
          def index
            @current_state = Models::ConsumersState.current!
            @counters = Models::Counters.new(@current_state)
            historicals = Models::Historicals.new(@current_state)
            # Load only historicals for the selected range
            @charts = Models::Charts.new(historicals, :seconds)

            respond
          end
        end
      end
    end
  end
end
