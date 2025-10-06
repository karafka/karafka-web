# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects metrics from containerized environments (Docker, Kubernetes)
            # Extends OS metrics with container-aware memory limit detection from cgroups
            # Supports both cgroups v1 and v2
            class Container < Os
              # Maximum value that represents "no limit" in cgroup v2
              CGROUP_V2_MAX = 'max'

              # Paths for cgroup detection and reading
              CGROUP_V2_CONTROLLERS = '/sys/fs/cgroup/cgroup.controllers'

              # Memory paths
              # Path to cgroup v1 memory limit file
              CGROUP_V1_MEMORY_LIMIT = '/sys/fs/cgroup/memory/memory.limit_in_bytes'
              # Path to cgroup v2 memory limit file
              CGROUP_V2_MEMORY_LIMIT = '/sys/fs/cgroup/memory.max'

              private_constant(
                :CGROUP_V2_MAX, :CGROUP_V2_CONTROLLERS,
                :CGROUP_V1_MEMORY_LIMIT, :CGROUP_V2_MEMORY_LIMIT
              )

              class << self
                # Checks if running in a containerized environment with cgroups
                # @return [Boolean] true if cgroups are available, false otherwise
                def active?
                  !cgroup_version.nil?
                end

                # Gets the memory limit for the container
                # @return [Integer, nil] memory limit in kilobytes, or nil if not available
                def memory_limit
                  return @memory_limit if instance_variable_defined?(:@memory_limit)

                  @memory_limit = case cgroup_version
                                  when :v2
                                    read_cgroup_v2_memory_limit
                                  when :v1
                                    read_cgroup_v1_memory_limit
                                  end
                end

                private

                # Detects which cgroup version is in use
                # @return [Symbol, nil] :v2, :v1, or nil if not in a cgroup environment
                def cgroup_version
                  return @cgroup_version if instance_variable_defined?(:@cgroup_version)

                  @cgroup_version = if File.exist?(CGROUP_V2_CONTROLLERS)
                                      :v2
                                    elsif File.exist?(CGROUP_V1_MEMORY_LIMIT)
                                      :v1
                                    end
                end

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
              end

              # @return [Integer] total amount of memory in kilobytes
              # In containerized environments, returns the container's memory limit from cgroups.
              # Falls back to host memory if no limit is set.
              def memory_size
                self.class.memory_limit || super
              end
            end
          end
        end
      end
    end
  end
end
