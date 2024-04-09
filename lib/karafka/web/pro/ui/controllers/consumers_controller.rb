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
    module Pro
      module Ui
        module Controllers
          # Controller for displaying consumers states and details about them
          class ConsumersController < BaseController
            include Web::Ui::Lib::Paginations

            self.sortable_attributes = %w[
              id
              process_id
              name
              status
              started_at
              lag_hybrid
              lag_hybrid_d
              committed_offset
              stored_offset
              fetch_state
              poll_state
              lso_risk_state
              topic
              consumer
              type
              messages
              first_offset
              last_offset
              updated_at
              memory_usage
              threads
              utilization
              busy
              workers
              active
              standby
              running_jobs_count
              pending_jobs_count
            ].freeze

            # Consumers list
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

            # Displays per-process performance details
            def performance
              index

              render
            end

            # Displays processes with details + ability to manage
            def controls
              index

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
              @process.consumer_groups.each do |consumer_group|
                # We need to initialize the whole structure so dynamic fields are also built into
                # the underlying hashes for sorting
                consumer_group.subscription_groups.flat_map(&:topics).flat_map(&:partitions)

                refine(consumer_group)
              end

              render
            end
          end
        end
      end
    end
  end
end
