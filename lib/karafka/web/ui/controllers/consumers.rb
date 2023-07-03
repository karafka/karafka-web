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
            @counters = Models::Counters.new(@current_state)
            @processes, last_page = Lib::PaginateArray.new.call(
              Models::Processes.active(@current_state),
              @params.current_page
            )

            @page_scope = Ui::Lib::PageScopes::PageBased.new(
              @params.current_page,
              !last_page
            )

            respond
          end
        end
      end
    end
  end
end
