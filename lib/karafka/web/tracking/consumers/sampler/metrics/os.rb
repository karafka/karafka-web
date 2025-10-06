# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects OS-level metrics from /proc filesystem and system commands
            # Used when running directly on a host OS (not in containers)
            class Os < Base
              # @param shell [MemoizedShell] shell executor for running system commands
              def initialize(shell)
                super()
                @shell = shell
              end

              # @return [Integer] memory used by this process in kilobytes (RSS - Resident Set Size)
              # This is the amount of physical memory currently used by the Karafka process.
              # On Linux: reads VmRSS from /proc/{pid}/status
              # On macOS: uses ps command to get RSS for current process
              # @note This represents ONLY the current Karafka process memory usage
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
                  shell
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

              # @param memory_threads_ps [Array, false] parsed ps/proc output for all processes
              # @return [Integer] total memory used by all processes in the system (or container)
              # This represents system-wide (or container-wide) memory usage by summing RSS
              # across all processes.
              # On bare metal: sums memory for all processes on the host
              # In containers: sums memory for all processes within the container (due to PID namespace)
              # @note This is DIFFERENT from memory_usage which only shows current process memory
              # @note Used in Web UI to show "OS memory used" metric
              def memory_total_usage(memory_threads_ps)
                return 0 unless memory_threads_ps

                memory_threads_ps.map(&:first).sum
              end

              # @return [Integer] total amount of available memory in kilobytes
              # This is the total physical memory available to the system/container.
              # On Linux: reads MemTotal from /proc/meminfo
              # On macOS: uses sysctl hw.memsize
              # In containers: Container class overrides this to return cgroup memory limit
              # @note This is a STATIC value (system RAM capacity), memoized for performance
              # @note Used in Web UI to show "OS memory available" metric
              def memory_size
                return @memory_size if instance_variable_defined?(:@memory_size)

                @memory_size = case RUBY_PLATFORM
                               when /linux/
                                 mem_info = File.read('/proc/meminfo')
                                 mem_total_line = mem_info.match(/MemTotal:\s*(?<total>\d+)/)
                                 mem_total_line['total'].to_i
                               when /darwin|bsd/
                                 shell
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
                when /linux/
                  File
                    .read('/proc/loadavg')
                    .split(' ')
                    .first(3)
                    .map(&:to_f)
                when /darwin|bsd/
                  shell
                    .call('w | head -1')
                    .strip
                    .split(' ')
                    .map(&:to_f)
                    .last(3)
                else
                  [-1, -1, -1]
                end
              end

              # @return [Integer] CPU count
              def cpus
                @cpus ||= Etc.nprocessors
              end

              # @param memory_threads_ps [Array, false] parsed ps output
              # @return [Integer] number of process threads
              # @note This returns total number of threads from the OS perspective including
              #   native extensions threads, etc.
              def threads(memory_threads_ps)
                return 0 unless memory_threads_ps

                memory_threads_ps.find { |row| row.last == ::Process.pid }[1]
              end

              # Loads process information for all running processes
              # @return [Array<Array<Integer, Integer, Integer>>, false] array of [rss_kb, threads, pid]
              #   for each process, or false if unavailable
              #
              # This method reads information about ALL processes on the system (or in the container).
              # The data is used by multiple metrics:
              # - memory_total_usage: sums RSS across all processes
              # - threads: extracts thread count for current process
              #
              # Format of each array element: [memory_in_kb, thread_count, process_id]
              # - memory_in_kb: RSS (Resident Set Size) in kilobytes
              # - thread_count: Number of threads (only populated for current process, 0 for others)
              # - process_id: Process ID
              #
              # Platform behavior:
              # - Linux: Reads /proc/[0-9]*/statm for ALL processes on host/container
              # - macOS: Uses `ps -A` to get all processes
              # - Containers: Due to PID namespaces, only sees processes within the container
              #
              # @note Sampler calls this once per sample cycle (every ~5 seconds) and caches the result
              #   in @memory_threads_ps to ensure consistent data within a single sample snapshot
              # @note The cache is refreshed on EVERY sample cycle, so data stays current
              # @note On Linux, thread count is only extracted for the current process to optimize performance
              def memory_threads_ps
                case RUBY_PLATFORM
                when /linux/
                  page_size = Helpers::Sysconf.page_size
                  current_pid = ::Process.pid

                  # Read all processes from /proc
                  Dir.glob('/proc/[0-9]*/statm').map do |statm_file|
                    pid = statm_file.match(%r{/proc/(\d+)/statm})[1].to_i
                    status_file = "/proc/#{pid}/status"

                    # Extract RSS from /proc/<pid>/statm (second field)
                    rss_pages = begin
                      File.read(statm_file).split[1].to_i
                    rescue StandardError
                      next # Process may have exited
                    end

                    # Extract thread count from /proc/<pid>/status (only for current process)
                    thcount = if pid == current_pid
                                begin
                                  File.read(status_file)[/^Threads:\s+(\d+)/, 1].to_i
                                rescue StandardError
                                  0
                                end
                              else
                                0
                              end

                    # Convert RSS from pages to kilobytes
                    rss_kb = (rss_pages * page_size) / 1024

                    [rss_kb, thcount, pid]
                  end.compact
                # thcount is not available on macos ps
                # because of that we inject 0 as threads count similar to how
                # we do on windows
                when /darwin|bsd/
                  shell
                    .call('ps -A -o rss=,pid=')
                    .split("\n")
                    .map { |row| row.strip.split(' ').map(&:to_i) }
                    .map { |row| [row.first, 0, row.last] }
                else
                  false
                end
              end

              private

              attr_reader :shell
            end
          end
        end
      end
    end
  end
end
