# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
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

              # @param process_id [String] id of the process we're interested in
              def details(process_id)
                current_state = Models::ConsumersState.current!
                @process = Models::Process.find(current_state, process_id)

                return render if @process.schema_compatible?

                raise Errors::Ui::IncompatibleSchemaError
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
end
