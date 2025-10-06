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

              # @param memory_threads_ps [Array, false] parsed ps output
              # @return [Integer] total memory used in the OS
              def memory_total_usage(memory_threads_ps)
                return 0 unless memory_threads_ps

                memory_threads_ps.map(&:first).sum
              end

              # @return [Integer] total amount of memory in kilobytes
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

              # Loads ps results into memory so we can extract from them whatever we need
              # @return [Array, false] array of [memory, threads, pid] or false if unavailable
              def memory_threads_ps
                case RUBY_PLATFORM
                when /linux/
                  page_size = Helpers::Sysconf.page_size
                  status_file = "/proc/#{::Process.pid}/status"

                  pid = status_file.match(%r{/proc/(\d+)/status})[1]

                  # Extract thread count from /proc/<pid>/status
                  thcount = File.read(status_file)[/^Threads:\s+(\d+)/, 1].to_i

                  # Extract RSS from /proc/<pid>/statm (second field)
                  statm_file = "/proc/#{pid}/statm"
                  rss_pages = begin
                    File.read(statm_file).split[1].to_i
                  rescue StandardError
                    0
                  end
                  # page size is retrieved from Sysconf
                  rss_kb = (rss_pages * page_size) / 1024

                  [[rss_kb, thcount, pid.to_i]]
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
