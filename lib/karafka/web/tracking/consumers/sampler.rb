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
          SCHEMA_VERSION = '1.4.1'

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
                polled_at: monotonic_now,
                topics: Hash.new do |h1, topic|
                  h1[topic] = Hash.new do |h2, partition|
                    # We track those details in case we need to fill statistical gaps for
                    # transactional consumers
                    h2[partition] = {
                      seek_offset: -1,
                      transactional: false
                    }
                  end
                end
              }
            end

            @errors = []
            @pauses = {}
            @jobs = {}
            @shell = MemoizedShell.new
            @memory_total_usage = 0
            @memory_usage = 0
            @cpu_usage = [-1, -1, -1]

            # Select and instantiate appropriate system metrics collector based on environment
            # Use container-aware collector if cgroups are available, otherwise use OS-based
            metrics_class = if Cgroup.version
                              Metrics::Container
                            else
                              Metrics::Os
                            end
            @system_metrics = metrics_class.new(@shell)
            @network_metrics = Metrics::Network.new(@windows)
            @server_metrics = Metrics::Server.new
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
                listeners: @server_metrics.listeners,
                workers: workers,
                memory_usage: @memory_usage,
                memory_total_usage: @memory_total_usage,
                memory_size: memory_size,
                cpus: cpus,
                threads: threads,
                cpu_usage: @cpu_usage,
                tags: Karafka::Process.tags,
                bytes_received: @network_metrics.bytes_received,
                bytes_sent: @network_metrics.bytes_sent
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

              stats: jobs_metrics.jobs_queue_statistics.merge(
                utilization: jobs_metrics.utilization
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

          # @return [Metrics::Jobs] jobs metrics instance
          # @note Lazy initialization since it depends on started_at and workers
          def jobs_metrics
            @jobs_metrics ||= Metrics::Jobs.new(@windows, started_at, workers)
          end

          # @return [Integer] memory used by this process in kilobytes
          def memory_usage
            @system_metrics.memory_usage
          end

          # Total memory used in the OS
          def memory_total_usage
            @system_metrics.memory_total_usage(@memory_threads_ps)
          end

          # @return [Integer] total amount of memory in kilobytes
          # In containerized environments (Docker/Kubernetes), this returns the container's
          # memory limit. Otherwise, returns the host's total memory.
          def memory_size
            @memory_size ||= @system_metrics.memory_size
          end

          # @return [Array<Float>] load averages for last 1, 5 and 15 minutes
          def cpu_usage
            @system_metrics.cpu_usage
          end

          # @return [Integer] number of process threads.
          # @note This returns total number of threads from the OS perspective including native
          #   extensions threads, etc.
          def threads
            @system_metrics.threads(@memory_threads_ps)
          end

          # @return [Integer] CPU count
          def cpus
            @cpus ||= @system_metrics.cpus
          end

          # @return [Integer] number of threads that process work
          def workers
            @workers ||= Karafka::App.config.concurrency
          end

          # Loads our ps results into memory so we can extract from them whatever we need
          def memory_threads_ps
            @memory_threads_ps = @system_metrics.memory_threads_ps
          end

          # Consumer group details need to be enriched with details about polling that comes from
          # Karafka level. It is also time based, hence we need to materialize it only at the
          # moment of message dispatch to have it accurate.
          def enriched_consumer_groups
            Enrichers::ConsumerGroups
              .new(@consumer_groups, @subscription_groups)
              .call
          end
        end
      end
    end
  end
end
