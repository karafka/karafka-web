# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Consumers (consuming processes - `karafka server`) processes display consumer
        class Consumers < Base
          # List page with consumers
          # @note For now we load all and paginate over the squashed data.
          def index
            @current_state = Models::State.current!
            processes_total = Models::Processes.active(@current_state)

            @counters = Lib::HashProxy.new(@current_state[:stats])
            @processes, @next_page = Lib::PaginateArray.new.call(
              processes_total,
              @params.current_page
            )

            respond
          end
        end
      end
    end
  end
end
