# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          # Class used to execute code that can fail but we do not want to fail the whole
          # operation. The primary use-case is for displaying deserialized data. We always need to
          # assume, that part of the data can be corrupted and it should not crash the whole UI.
          #
          # It caches the result and does not run the code twice (only once). Additionally, it
          # measures the CPU usage and total time during the execution of the code block.
          class SafeRunner
            include Karafka::Core::Helpers::Time

            attr_reader :error, :result, :cpu_time, :total_time, :allocations

            # @param block [Proc] code we want to safe-guard
            def initialize(&block)
              @code = block
              @executed = false
              @success = false
              @error = nil
              @result = nil
              @cpu_time = 0
              @total_time = 0
              @allocations = false
            end

            # @return [Boolean] was the code execution successful or not
            def success?
              return @success if executed?

              call

              @success
            end

            # @return [Boolean] was the code execution failed or not
            def failure?
              !success?
            end

            # Runs the execution and returns block result
            def call
              return @result if executed?

              @executed = true

              if objspace?
                ObjectSpace.trace_object_allocations_start
                before = ObjectSpace.each_object.count
              end

              # We measure time as close to the process as possible so it is not impacted by the
              # objects allocations count (if applicable)
              start_time = monotonic_now
              start_cpu = ::Process.times
              @result = @code.call
              @success = true

              @result
            rescue StandardError => e
              @error = e
              @success = false
            ensure
              end_time = monotonic_now
              end_cpu = ::Process.times

              @cpu_time = (
                (end_cpu.utime - start_cpu.utime) + (end_cpu.stime - start_cpu.stime)
              ) * 1_000
              @total_time = (end_time - start_time)

              if objspace?
                @allocations = ObjectSpace.each_object.count - before
                ObjectSpace.trace_object_allocations_stop
              end
            end

            # @return [Boolean] was the code executed already or not yet
            def executed?
              @executed
            end

            private

            # @return [Boolean] true if tracing is available
            def objspace?
              ObjectSpace.respond_to?(:trace_object_allocations_start)
            end
          end
        end
      end
    end
  end
end
