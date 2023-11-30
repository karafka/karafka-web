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
                refine(Models::Processes.active(@current_state)),
                @params.current_page
              )

              paginate(@params.current_page, !last_page)

              render
            end

            # @param process_id [String] id of the process we're interested in
            def details(process_id)
              current_state = Models::ConsumersState.current!
              @process = Models::Process.find(current_state, process_id)

              render
            end

            # Renders details about running jobs
            #
            # @param process_id [String] id of the process we're interested in
            def running_jobs(process_id)
              details(process_id)

              @running_jobs = @process.jobs.running

              refine(@running_jobs)

              render
            end

            # Renders details about pending jobs
            #
            # @param process_id [String] id of the process we're interested in
            def pending_jobs(process_id)
              details(process_id)

              @pending_jobs = @process.jobs.pending

              refine(@pending_jobs)

              render
            end

            # @param process_id [String] id of the process we're interested in
            def subscriptions(process_id)
              details(process_id)

              # We want to have sorting but on a per subscription group basis and not to sort
              # everything
              @process.consumer_groups.each { |subscription_group| refine(subscription_group) }

              render
            end
          end
        end
      end
    end
  end
end
