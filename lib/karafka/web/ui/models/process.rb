# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single consumer process representation
        class Process < Lib::HashProxy
          class << self
            # Looks for a given process based on its id
            # @param state [State] state of the system based on which we will do the lookup
            # @param process_id [String] id of the process we are looking for
            # @return [Process] selected process or error raised
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] raised if process not found
            def find(state, process_id)
              found_process = Processes.active(state).find { |process| process.id == process_id }
              found_process || raise(::Karafka::Web::Errors::Ui::NotFoundError, process_id)
            end
          end

          # @return [Array<ConsumerGroup>] consumer groups to which this process is subscribed in
          #   an alphabetical order
          def consumer_groups
            super
              .values
              .map { |cg_hash| ConsumerGroup.new(cg_hash) }
              .sort_by(&:id)
          end

          # Jobs sorted from longest running to youngest
          # @return [Array<Job>] current jobs of this process
          def jobs
            super
              .map { |job| Job.new(job) }
              .sort_by(&:updated_at)
              .then { |jobs| Jobs.new(jobs) }
          end

          # @return [Integer] number of running jobs on a process
          def running_jobs_count
            jobs.running.count
          end

          # @return [Integer] number of pending jobs on a process
          def pending_jobs_count
            jobs.pending.count
          end

          # @return [Integer] collective hybrid lag on this process
          def lag_hybrid
            consumer_groups
              .flat_map(&:subscription_groups)
              .flat_map(&:topics)
              .flat_map(&:partitions)
              .map(&:lag_hybrid)
              .delete_if(&:negative?)
              .sum
          end

          # @return [Boolean] true if there are any active subscriptions, otherwise false.
          def subscribed?
            return false if consumer_groups.empty?

            consumer_groups.any? do |cg|
              !cg.subscription_groups.empty?
            end
          end

          # @return [Integer] number of partitions to which we are currently subscribed
          def subscribed_partitions_count
            consumer_groups
              .flat_map(&:subscription_groups)
              .flat_map(&:topics)
              .flat_map(&:partitions)
              .count
          end
        end
      end
    end
  end
end
