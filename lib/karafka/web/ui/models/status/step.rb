# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          # Represents the result of a single status check step.
          #
          # Each check in the status flow returns a Step that contains:
          # - The status of the check (:success, :warning, :failure, or :halted)
          # - Optional details hash with check-specific information
          #
          # @example Creating a successful step
          #   Step.new(:success, { time: 150 })
          #
          # @example Creating a halted step (dependency failed)
          #   Step.new(:halted, nil)
          Step = Struct.new(:status, :details) do
            # Checks if the step completed successfully (allows chain to continue).
            #
            # Both :success and :warning are considered successful because warnings
            # don't block the dependency chain - they just notify about potential issues.
            #
            # @return [Boolean] true if status is :success or :warning
            def success?
              %i[success warning].include?(status)
            end

            # Returns the partial namespace for rendering the appropriate view.
            #
            # Maps the status to a directory name used for view partial lookup:
            # - :success -> 'successes'
            # - :warning -> 'warnings'
            # - :failure -> 'failures'
            # - :halted  -> 'failures' (halted checks show failure partial)
            #
            # @return [String] the partial namespace directory name
            # @raise [Karafka::Errors::UnsupportedCaseError] if status is unknown
            def partial_namespace
              case status
              when :success then 'successes'
              when :warning then 'warnings'
              when :failure then 'failures'
              when :halted  then 'failures'
              else
                raise ::Karafka::Errors::UnsupportedCaseError, status
              end
            end

            # Returns the string representation of the status.
            #
            # Used by views to dynamically select the appropriate partial template.
            #
            # @return [String] the status as a string
            def to_s
              status.to_s
            end
          end
        end
      end
    end
  end
end
