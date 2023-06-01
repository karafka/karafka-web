# frozen_string_literal: true

module Karafka
  module Web
    # Namespace used to encapsulate all components needed to track and report states of particular
    # processes
    module Tracking
      # Class used to run shell command that also returns previous result in case of a failure
      # This is used because children can get signals when performing stat fetches and then
      # fetch is stopped. This can cause invalid results from sub-shell commands.
      #
      # This will return last result as log as there was one.
      class MemoizedShell
        # Hpw many tries do we want to perform before giving up on the shell command
        MAX_ATTEMPTS = 4

        private_constant :MAX_ATTEMPTS

        def initialize
          @accu = {}
        end

        # @param cmd [String]
        # @return [String, nil] sub-shell evaluation string result or nil if we were not able to
        #   run or re-run the call.
        def call(cmd)
          attempt ||= 0

          while attempt < MAX_ATTEMPTS
            attempt += 1

            stdout_str, status = Open3.capture2(cmd)

            if status.success?
              @accu[cmd] = stdout_str
              return stdout_str
            else
              return stdout_str if attempt > MAX_ATTEMPTS
              return @accu[cmd] if @accu.key?(cmd)
            end
          end

          @accu[cmd]
        end
      end
    end
  end
end
