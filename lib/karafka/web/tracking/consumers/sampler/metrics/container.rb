# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects metrics from containerized environments (Docker, Kubernetes)
            # Uses cgroup information when available, delegates to OS metrics otherwise
            class Container < Base
              # @param shell [MemoizedShell] shell executor for running system commands
              def initialize(shell)
                super()
                @os_metrics = Os.new(shell)
              end

              # @return [Integer] memory used by this process in kilobytes
              def memory_usage
                os_metrics.memory_usage
              end

              # @param memory_threads_ps [Array, false] parsed ps output
              # @return [Integer] total memory used in the OS
              def memory_total_usage(memory_threads_ps)
                os_metrics.memory_total_usage(memory_threads_ps)
              end

              # @return [Integer] total amount of memory in kilobytes
              # In containerized environments, returns the container's memory limit.
              # Falls back to host memory if no limit is set.
              def memory_size
                # Try to get container memory limit first (Docker/Kubernetes)
                # Fall back to OS metrics if not in a container or no limit set
                Cgroup.memory_limit || os_metrics.memory_size
              end

              # @return [Array<Float>] load averages for last 1, 5 and 15 minutes
              def cpu_usage
                os_metrics.cpu_usage
              end

              # @return [Integer] CPU count
              # @note Could potentially use cgroup CPU limits in the future
              def cpus
                os_metrics.cpus
              end

              # @param memory_threads_ps [Array, false] parsed ps output
              # @return [Integer] number of process threads
              def threads(memory_threads_ps)
                os_metrics.threads(memory_threads_ps)
              end

              # @return [Array, false] array of [memory, threads, pid] or false if unavailable
              def memory_threads_ps
                os_metrics.memory_threads_ps
              end

              private

              attr_reader :os_metrics
            end
          end
        end
      end
    end
  end
end
