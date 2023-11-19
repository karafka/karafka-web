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

          # @return [String] process id without the name and ip
          def id
            @id ||= name.split(':').last
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

          # @return [Integer] collective stored lag on this process
          def lag_stored
            consumer_groups
              .flat_map(&:subscription_groups)
              .flat_map(&:topics)
              .flat_map(&:partitions)
              .map(&:lag_stored)
              .delete_if(&:negative?)
              .sum
          end

          # @return [Integer] collective lag on this process
          def lag
            consumer_groups
              .flat_map(&:subscription_groups)
              .flat_map(&:topics)
              .flat_map(&:partitions)
              .map(&:lag)
              .delete_if(&:negative?)
              .sum
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
