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

          # Last three methods are needed to provide sorting
          def_delegators :@jobs_array, :empty?, :size, :map!, :sort_by!, :reverse!

          # @param jobs_array [Array<Job>] all jobs we want to enclose
          def initialize(jobs_array)
            @jobs_array = jobs_array
          end

          # @return [Jobs] running jobs
          def running
            select { |job| job.status == "running" }
          end

          # @return [Jobs] pending jobs
          def pending
            select { |job| job.status == "pending" }
          end

          # Creates a new Jobs object with selected jobs
          # @return [Jobs] selected jobs enclosed with the Jobs object
          def select(&)
            self.class.new(super)
          end

          # Allows for iteration over jobs
          def each(&)
            @jobs_array.each(&)
          end
        end
      end
    end
  end
end
