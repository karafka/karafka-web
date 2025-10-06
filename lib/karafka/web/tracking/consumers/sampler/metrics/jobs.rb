# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects job queue statistics and worker utilization metrics
            class Jobs < Base
              include ::Karafka::Core::Helpers::Time

              # @param windows [Helpers::Ttls::Windows] time windows for aggregating metrics
              # @param started_at [Float] process start time
              # @param workers [Integer] number of worker threads
              def initialize(windows, started_at, workers)
                super()
                @windows = windows
                @started_at = started_at
                @workers = workers
              end

              # @return [Numeric] % utilization of all the threads. 100% means all the threads are
              #   utilized all the time within the given time window. 0% means, nothing is happening
              #   most if not all the time.
              def utilization
                totals = windows.m1[:processed_total_time]

                return 0 if totals.empty?

                timefactor = float_now - started_at
                timefactor = timefactor > 60 ? 60 : timefactor

                # We divide by 1_000 to convert from milliseconds
                # We multiply by 100 to have it in % scale
                (totals.sum / 1_000 / workers / timefactor * 100).round(2)
              end

              # @return [Hash] job queue statistics
              def jobs_queue_statistics
                # We return empty stats in case jobs queue is not yet initialized
                base = Karafka::Server.jobs_queue&.statistics || { busy: 0, enqueued: 0 }
                stats = base.slice(:busy, :enqueued, :waiting)
                stats[:waiting] ||= 0
                # busy - represents number of jobs that are being executed currently
                # enqueued - jobs that are in the queue but not being picked up yet
                # waiting - jobs that are not scheduled on the queue but will be
                # be enqueued in case of advanced schedulers
                stats
              end

              private

              attr_reader :windows, :started_at, :workers
            end
          end
        end
      end
    end
  end
end
