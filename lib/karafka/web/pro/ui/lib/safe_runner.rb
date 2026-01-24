# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
                GC.disable
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
                GC.enable
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
