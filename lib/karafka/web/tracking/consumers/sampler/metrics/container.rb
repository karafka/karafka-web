# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects metrics from containerized environments (Docker, Kubernetes)
            # Extends OS metrics with container-aware memory limit detection from cgroups
            class Container < Os
              # @return [Integer] total amount of memory in kilobytes
              # In containerized environments, returns the container's memory limit from cgroups.
              # Falls back to host memory if no limit is set.
              def memory_size
                # Try to get container memory limit first (Docker/Kubernetes)
                # Fall back to OS metrics if not in a container or no limit set
                Cgroup.memory_limit || super
              end
            end
          end
        end
      end
    end
  end
end
