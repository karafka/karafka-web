# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Class used to execute code that can fail but we do not want to fail the whole operation.
        # The primary use-case is for displaying deserialized data. We always need to assume, that
        # part of the data can be corrupted and it should not crash the whole UI.
        #
        # It caches the result and does not run the code twice (only once)
        class SafeRunner
          attr_reader :error, :result

          # @param block [Proc] code we want to safe-guard
          def initialize(&block)
            @code = block
            @executed = false
            @success = false
            @error = nil
            @result = nil
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
            @result = @code.call
            @success = true
            @result
          rescue StandardError => e
            @error = e
            @success = false
          end

          # @return [Boolean] was the code executed already or not yet
          def executed?
            @executed
          end
        end
      end
    end
  end
end
