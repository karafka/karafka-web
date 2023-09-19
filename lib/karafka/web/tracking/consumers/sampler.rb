# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for all the things related to tracking consumers and consuming processes
      module Consumers
        # Samples for fetching and storing metrics samples about the consumer process
        class Sampler < Tracking::Sampler
          include ::Karafka::Core::Helpers::Time

          attr_reader :counters, :consumer_groups, :errors, :times, :pauses, :jobs

          # Current schema version
          # This can be used in the future for detecting incompatible changes and writing
          # migrations
          SCHEMA_VERSION = '1.2.3'

          # 60 seconds window for time tracked window-based metrics
          TIMES_TTL = 60

          # Times ttl in ms
          TIMES_TTL_MS = TIMES_TTL * 1_000

          # Counters that count events occurrences during the given window
          COUNTERS_BASE = {
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

          private_constant :TIMES_TTL, :TIMES_TTL_MS, :COUNTERS_BASE

          def initialize
            super

            @counters = COUNTERS_BASE.dup
            @times = TtlHash.new(TIMES_TTL_MS)
            @consumer_groups = {}
            @errors = []
            @started_at = float_now
            @pauses = Set.new
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
                started_at: @started_at,
                name: process_name,
                status: ::Karafka::App.config.internal.status.to_s,
                listeners: listeners,
                workers: workers,
                memory_usage: @memory_usage,
                memory_total_usage: @memory_total_usage,
                memory_size: memory_size,
                cpus: cpus,
                threads: threads,
                cpu_usage: @cpu_usage,
                tags: Karafka::Process.tags
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

              consumer_groups: @consumer_groups,
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

          # @return [Numeric] % utilization of all the threads. 100% means all the threads are
          #   utilized all the time within the given time window. 0% means, nothing is happening
          #   most if not all the time.
          def utilization
            return 0 if times[:total].empty?

            # Max times ttl
            timefactor = float_now - @started_at
            timefactor = timefactor > TIMES_TTL ? TIMES_TTL : timefactor

            # We divide by 1_000 to convert from milliseconds
            # We multiply by 100 to have it in % scale
            times[:total].sum / 1_000 / workers / timefactor * 100
          end

          # @return [Integer] number of listeners
          def listeners
            # This can be zero before the server starts
            Karafka::Server.listeners&.count.to_i
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
            # busy - represents number of jobs that are being executed currently
            # enqueued - represents number of jobs that are enqueued to be processed
            Karafka::Server.jobs_queue&.statistics || { busy: 0, enqueued: 0 }
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
        end
      end
    end
  end
end
