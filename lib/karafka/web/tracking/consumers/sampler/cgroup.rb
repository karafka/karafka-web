# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          # Helper module for reading cgroup (container) metrics
          # Supports both cgroups v1 and v2 for Docker/Kubernetes environments
          module Cgroup
            # Maximum value that represents "no limit" in cgroup v2
            CGROUP_V2_MAX = 'max'

            # Paths for cgroup detection and reading
            CGROUP_V2_CONTROLLERS = '/sys/fs/cgroup/cgroup.controllers'

            # Memory paths
            # Path to cgroup v1 memory limit file
            CGROUP_V1_MEMORY_LIMIT = '/sys/fs/cgroup/memory/memory.limit_in_bytes'
            # Path to cgroup v2 memory limit file
            CGROUP_V2_MEMORY_LIMIT = '/sys/fs/cgroup/memory.max'

            # CPU paths (for future use)
            # Path to cgroup v1 CPU shares file
            CGROUP_V1_CPU_SHARES = '/sys/fs/cgroup/cpu/cpu.shares'
            # Path to cgroup v2 CPU max file (contains quota and period)
            CGROUP_V2_CPU_MAX = '/sys/fs/cgroup/cpu.max'
            # Path to cgroup v2 CPU weight file
            CGROUP_V2_CPU_WEIGHT = '/sys/fs/cgroup/cpu.weight'

            class << self
              # Detects which cgroup version is in use
              # @return [Symbol, nil] :v2, :v1, or nil if not in a cgroup environment
              def version
                return @version if instance_variable_defined?(:@version)

                @version = if File.exist?(CGROUP_V2_CONTROLLERS)
                             :v2
                           elsif File.exist?(CGROUP_V1_MEMORY_LIMIT)
                             :v1
                           end
              end

              # Gets the memory limit for the container
              # @return [Integer, nil] memory limit in kilobytes, or nil if not available
              def memory_limit
                case version
                when :v2
                  read_cgroup_v2_memory_limit
                when :v1
                  read_cgroup_v1_memory_limit
                end
              end

              # Gets the CPU quota for the container (if set)
              # @return [Float, nil] number of CPUs allocated, or nil if not available
              def cpu_limit
                case version
                when :v2
                  read_cgroup_v2_cpu_limit
                when :v1
                  read_cgroup_v1_cpu_limit
                end
              end

              private

              # Reads memory limit from cgroup v2
              # @return [Integer, nil] memory limit in kilobytes, or nil
              def read_cgroup_v2_memory_limit
                return nil unless File.exist?(CGROUP_V2_MEMORY_LIMIT)

                limit = File.read(CGROUP_V2_MEMORY_LIMIT).strip

                # "max" means no limit
                return nil if limit == CGROUP_V2_MAX

                # Convert from bytes to kilobytes
                limit.to_i / 1024
              rescue StandardError
                nil
              end

              # Reads memory limit from cgroup v1
              # @return [Integer, nil] memory limit in kilobytes, or nil
              def read_cgroup_v1_memory_limit
                return nil unless File.exist?(CGROUP_V1_MEMORY_LIMIT)

                limit = File.read(CGROUP_V1_MEMORY_LIMIT).strip.to_i

                # Very large values (close to max int64) mean no limit
                # Using a threshold of 2^60 as a reasonable "unlimited" indicator
                return nil if limit > (2**60)

                # Convert from bytes to kilobytes
                limit / 1024
              rescue StandardError
                nil
              end

              # Reads CPU limit from cgroup v2
              # @return [Float, nil] number of CPUs, or nil
              def read_cgroup_v2_cpu_limit
                return nil unless File.exist?(CGROUP_V2_CPU_MAX)

                content = File.read(CGROUP_V2_CPU_MAX).strip

                # Format is "quota period" or "max period"
                quota, period = content.split(' ')

                return nil if quota == CGROUP_V2_MAX
                return nil unless period

                # Calculate CPUs as quota/period
                (quota.to_f / period.to_i).round(2)
              rescue StandardError
                nil
              end

              # Reads CPU limit from cgroup v1
              # @return [Float, nil] CPU shares (not directly convertible to CPU count)
              # Note: cpu.shares is a relative weight, not an absolute limit
              def read_cgroup_v1_cpu_limit
                return nil unless File.exist?(CGROUP_V1_CPU_SHARES)

                # cpu.shares is a relative weight (default 1024), not a direct CPU count
                # We return nil here as it's not a meaningful absolute limit
                # Could be enhanced in the future if needed
                nil
              rescue StandardError
                nil
              end
            end
          end
        end
      end
    end
  end
end
