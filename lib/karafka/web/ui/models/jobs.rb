# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Model representing group of jobs
        #
        # It simplifies filtering on running jobs and others, etc
        class Jobs
          include Enumerable
          extend Forwardable

          def_delegators :@jobs_array, :empty?, :size

          # @param jobs_array [Array<Job>] all jobs we want to enclose
          def initialize(jobs_array)
            @jobs_array = jobs_array
          end

          # @return [Jobs] running jobs
          def running
            select { |job| job.status == 'running' }
          end

          # Creates a new Jobs object with selected jobs
          # @param block [Proc] select proc
          # @return [Jobs] selected jobs enclosed with the Jobs object
          def select(&block)
            self.class.new(super(&block))
          end

          # Allows for iteration over jobs
          # @param block [Proc] block to call for each job
          def each(&block)
            @jobs_array.each(&block)
          end
        end
      end
    end
  end
end
