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
          # Controller for displaying consumers states and details about them
          class Consumers < Ui::Controllers::Base
            # Consumers list
            def index
              @current_state = Models::ConsumersState.current!
              @counters = Models::Counters.new(@current_state)
              @processes, last_page = Lib::Paginations::Paginators::Arrays.call(
                Models::Processes.active(@current_state),
                @params.current_page
              )

              paginate(@params.current_page, !last_page)

              respond
            end

            # @param process_id [String] id of the process we're interested in
            def jobs(process_id)
              current_state = Models::ConsumersState.current!
              @process = Models::Process.find(current_state, process_id)

              respond
            end

            # @param process_id [String] id of the process we're interested in
            def subscriptions(process_id)
              current_state = Models::ConsumersState.current!
              @process = Models::Process.find(current_state, process_id)

              respond
            end
          end
        end
      end
    end
  end
end
