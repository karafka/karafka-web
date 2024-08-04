# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for all the things related to tracking consumers and consuming processes
      module Consumers
        # Samples for fetching and storing metrics samples about the consumer process
        class Sampler < Tracking::Sampler
          include ::Karafka::Core::Helpers::Time

          attr_reader :counters, :consumer_groups, :subscription_groups, :errors,
                      :pauses, :jobs, :windows

          # Current schema version
          # This is used for detecting incompatible changes and not using outdated data during
          # upgrades
          SCHEMA_VERSION = '1.4.0'

          # Counters that count events occurrences during the given window
          COUNTERS_BASE = {
            # Number of processed jobs of any type
            jobs: 0,
            # Number of processed batches
            batches: 0,
            # Number of processed messages
            messages: 0,
            # Number of errors that occurred
            errors: 0,
            # Number of retries that occurred
            retries: 0,
            # Number of messages considered dead
            dead: 0
          }.freeze

          private_constant :COUNTERS_BASE

          def initialize
            super

            @windows = Helpers::Ttls::Windows.new
            @counters = COUNTERS_BASE.dup

            @consumer_groups = Hash.new do |h, cg_id|
              h[cg_id] = {
                id: cg_id,
                subscription_groups: {}
              }
            end

            @subscription_groups = Hash.new do |h, sg_id|
              h[sg_id] = {
                id: sg_id,
                polled_at: monotonic_now
              }
            end

            @errors = []
            @pauses = {}
            @jobs = {}
            @shell = MemoizedShell.new
            @memory_total_usage = 0
            @memory_usage = 0
            @cpu_usage = [-1, -1, -1]
          end

          # We cannot report and track the same time, that is why we use mutex here. To make sure
          # that samples aggregations and counting does not interact with reporter flushing.
          def track
            Reporter::MUTEX.synchronize do
              yield(self)
            end
          end

          # @return [Hash] report hash with all the details about consumer operations
          def to_report
            {
              schema_version: SCHEMA_VERSION,
              type: 'consumer',
              dispatched_at: float_now,

              process: {
                id: process_id,
                started_at: started_at,
                status: ::Karafka::App.config.internal.status.to_s,
                execution_mode: ::Karafka::Server.execution_mode.to_s,
                listeners: listeners,
                workers: workers,
                memory_usage: @memory_usage,
                memory_total_usage: @memory_total_usage,
                memory_size: memory_size,
                cpus: cpus,
                threads: threads,
                cpu_usage: @cpu_usage,
                tags: Karafka::Process.tags,
                bytes_received: bytes_received,
                bytes_sent: bytes_sent
              },

              versions: {
                ruby: ruby_version,
                karafka: karafka_version,
                karafka_core: karafka_core_version,
                karafka_web: karafka_web_version,
                waterdrop: waterdrop_version,
                rdkafka: rdkafka_version,
                librdkafka: librdkafka_version
              },

              stats: jobs_queue_statistics.merge(
                utilization: utilization
              ).merge(total: @counters),

              consumer_groups: enriched_consumer_groups,
              jobs: jobs.values
            }
          end

          # Clears counters and errors.
          # Used after data is reported by reported to start collecting new samples
          # @note We do not clear processing or pauses or other things like this because we track
          #   their states and not values, so they need to be tracked between flushes.
          def clear
            @counters.each { |k, _| @counters[k] = 0 }

            @errors.clear
          end

          # @note This should run before any mutex, so other threads can continue as those
          #   operations may invoke shell commands
          def sample
            memory_threads_ps

            @memory_usage = memory_usage
            @memory_total_usage = memory_total_usage
            @cpu_usage = cpu_usage
            @threads = threads
          end

          private

          # @return [Float] time of start of this process
          # @note We memoize it on first run as forks should have their creation time matching the
          #   fork time.
          def started_at
            @started_at ||= float_now
          end

          # @return [Numeric] % utilization of all the threads. 100% means all the threads are
          #   utilized all the time within the given time window. 0% means, nothing is happening
          #   most if not all the time.
          def utilization
            totals = windows.m1[:processed_total_time]

            return 0 if totals.empty?

            timefactor = float_now - @started_at
            timefactor = timefactor > 60 ? 60 : timefactor

            # We divide by 1_000 to convert from milliseconds
            # We multiply by 100 to have it in % scale
            (totals.sum / 1_000 / workers / timefactor * 100).round(2)
          end

          # @return [Hash] number of active and standby listeners
          def listeners
            if Karafka::Server.listeners
              active = Karafka::Server.listeners.count(&:active?)
              total = Karafka::Server.listeners.count.to_i

              { active: active, standby: total - active }
            else
              { active: 0, standby: 0 }
            end
          end

          # @return [Integer] memory used by this process in kilobytes
          def memory_usage
            pid = ::Process.pid

            case RUBY_PLATFORM
            # Reading this that way is cheaper than running a shell command
            when /linux/
              IO.readlines("/proc/#{pid}/status").each do |line|
                next unless line.start_with?('VmRSS:')

                break line.split[1].to_i
              end
            when /darwin|bsd/
              @shell
                .call("ps -o pid,rss -p #{pid}")
                .lines
                .last
                .split
                .last
                .to_i
            else
              0
            end
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

          # Total memory used in the OS
          def memory_total_usage
            return 0 unless @memory_threads_ps

            @memory_threads_ps.map(&:first).sum
          end

          # @return [Integer] total amount of memory
          def memory_size
            @memory_size ||= case RUBY_PLATFORM
                             when /linux/
                               @shell
                             .call('grep MemTotal /proc/meminfo')
                             .match(/(\d+)/)
                             .to_s
                             .to_i
                             when /darwin|bsd/
                               @shell
                             .call('sysctl -a')
                             .split("\n")
                             .find { |line| line.start_with?('hw.memsize:') }
                             .to_s
                             .split(' ')
                             .last
                             .to_i
                             else
                               0
                             end
          end

          # @return [Array<Float>] load averages for last 1, 5 and 15 minutes
          def cpu_usage
            case RUBY_PLATFORM
            when /darwin|bsd|linux/
              @shell
                .call('w | head -1')
                .strip
                .split(' ')
                .map(&:to_f)
                .last(3)
            else
              [-1, -1, -1]
            end
          end

          # @return [Integer] number of process threads.
          # @note This returns total number of threads from the OS perspective including native
          #   extensions threads, etc.
          def threads
            return 0 unless @memory_threads_ps

            @memory_threads_ps.find { |row| row.last == ::Process.pid }[1]
          end

          # @return [Integer] CPU count
          def cpus
            @cpus ||= Etc.nprocessors
          end

          # @return [Integer] number of threads that process work
          def workers
            @workers ||= Karafka::App.config.concurrency
          end

          # Loads our ps results into memory so we can extract from them whatever we need
          def memory_threads_ps
            @memory_threads_ps = case RUBY_PLATFORM
                                 when /linux/
                                   @shell
                                 .call('ps -A -o rss=,thcount=,pid=')
                                 .split("\n")
                                 .map { |row| row.strip.split(' ').map(&:to_i) }
                                 # thcount is not available on macos ps
                                 # because of that we inject 0 as threads count similar to how
                                 # we do on windows
                                 when /darwin|bsd/
                                   @shell
                                 .call('ps -A -o rss=,pid=')
                                 .split("\n")
                                 .map { |row| row.strip.split(' ').map(&:to_i) }
                                 .map { |row| [row.first, 0, row.last] }
                                 else
                                   @memory_threads_ps = false
                                 end
          end

          # Consumer group details need to be enriched with details about polling that comes from
          # Karafka level. It is also time based, hence we need to materialize it only at the
          # moment of message dispatch to have it accurate.
          def enriched_consumer_groups
            @consumer_groups.each_value do |cg_details|
              cg_details.each do
                cg_details.fetch(:subscription_groups, {}).each do |sg_id, sg_details|
                  # This should be always available, since the subscription group polled at time
                  # is first initialized before we start polling, there should be no case where
                  # we have statistics about a given subscription group but we do not have the
                  # last polling time
                  polled_at = subscription_groups.fetch(sg_id).fetch(:polled_at)
                  sg_details[:state][:poll_age] = (monotonic_now - polled_at).round(2)
                end
              end
            end

            @consumer_groups
          end

          # @return [Integer] number of bytes received per second out of a one minute time window
          #   by all the consumers
          # @note We use one minute window to compensate for cases where metrics would be reported
          #   or recorded faster or slower. This normalizes data
          def bytes_received
            @windows
              .m1
              .stats_from { |k, _v| k.end_with?('rxbytes') }
              .rps
              .round
          end

          # @return [Integer] number of bytes sent per second out of a one minute time window by
          #   all the consumers
          def bytes_sent
            @windows
              .m1
              .stats_from { |k, _v| k.end_with?('txbytes') }
              .rps
              .round
          end
        end
      end
    end
  end
end
