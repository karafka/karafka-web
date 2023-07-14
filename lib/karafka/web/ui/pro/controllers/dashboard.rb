# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Pro
        module Controllers
          class Dashboard < Ui::Controllers::Base
            def index
              @current_state = Models::State.current!
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
