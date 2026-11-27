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

              # @param processing_times [Helpers::Ttls::Sum] processing times of the last minute
              # @param started_at [Float] process start time
              def initialize(processing_times, started_at)
                super()
                @processing_times = processing_times
                @started_at = started_at
              end

              # @return [Numeric] % utilization of all the threads. 100% means all the threads are
              #   utilized all the time within the given time window. 0% means, nothing is happening
              #   most if not all the time.
              def utilization
                return 0 if processing_times.empty?

                timefactor = [float_now - started_at, 60].min

                workers_count = workers

                # If downscaled completely (edge case) we return 0 because no way to compute
                return 0 if workers_count.zero?

                # We divide by 1_000 to convert from milliseconds
                # We multiply by 100 to have it in % scale
                (processing_times.sum / 1_000 / workers_count / timefactor * 100).round(2)
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

              attr_reader :processing_times, :started_at

              # @return [Integer] current number of worker threads
              # @note Not memoized because the thread pool can be dynamically scaled at runtime
              def workers
                Karafka::Server.workers.size
              end
            end
          end
        end
      end
    end
  end
end
