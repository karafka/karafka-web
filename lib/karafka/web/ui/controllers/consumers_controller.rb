# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Consumers (consuming processes - `karafka server`) processes display consumer
        class ConsumersController < BaseController
          self.sortable_attributes = %w[
            id
            started_at
            lag_hybrid
          ].freeze

          # List page with consumers
          # @note For now we load all and paginate over the squashed data.
          def index
            @current_state = Models::ConsumersState.current!
            @counters = Models::Counters.new(@current_state)
            @processes, last_page = Paginators::Arrays.call(
              refine(Models::Processes.active(@current_state)),
              @params.current_page
            )

            paginate(@params.current_page, !last_page)

            render
          end
        end
      end
    end
  end
end
