# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          # Namespace for all individual status check classes.
          #
          # Each check is a separate class that inherits from Base and implements
          # the DSL for declaring dependencies and check behavior.
          module Checks
            # Base class for all status checks.
            #
            # Provides a DSL for declaring check dependencies and characteristics,
            # as well as common functionality for executing checks.
            #
            # @example Creating a simple independent check
            #   class Enabled < Base
            #     independent!
            #
            #     def call
            #       enabled = ::Karafka::App.routes.map(&:name).include?(
            #         ::Karafka::Web.config.group_id
            #       )
            #       step(enabled ? :success : :failure)
            #     end
            #   end
            #
            # @example Creating a dependent check
            #   class Connection < Base
            #     depends_on :enabled
            #
            #     def call
            #       # Implementation...
            #       step(:success, { time: context.connection_time })
            #     end
            #   end
            class Base
              class << self
                # @return [Symbol, nil] the dependency check name, or nil if independent
                attr_reader :dependency

                # Declares that this check depends on another check.
                #
                # When a check has a dependency, it will be halted if the dependency
                # fails.
                #
                # @param check_name [Symbol] the name of the check this depends on
                # @return [Symbol] the dependency name
                #
                # @example
                #   class Connection < Base
                #     depends_on :enabled
                #   end
                def depends_on(check_name)
                  @dependency = check_name
                end

                # Marks this check as independent (no dependencies).
                #
                # Independent checks don't depend on any other check and will
                # always execute regardless of other check results.
                #
                # @return [Boolean] true
                def independent!
                  @independent = true
                end

                # Checks if this is an independent check.
                #
                # @return [Boolean] true if this check has no dependencies
                def independent?
                  @independent || false
                end

                # Returns the halted details for this check.
                #
                # Override this method in subclasses to provide specific details
                # when the check is halted due to dependency failure.
                #
                # @return [Hash, Array, nil] the default details for halted state
                def halted_details
                  nil
                end

                # Derives the check name from the class name.
                #
                # Converts CamelCase to snake_case.
                #
                # @return [Symbol] the check name
                #
                # @example
                #   Connection.check_name        #=> :connection
                #   InitialConsumersState.check_name #=> :initial_consumers_state
                def check_name
                  name
                    .split('::')
                    .last
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .downcase
                    .to_sym
                end
              end

              # Initializes the check with a shared context.
              #
              # @param context [Status::Context] the shared context containing
              #   cached data and configuration helpers
              def initialize(context)
                @context = context
              end

              # Executes the check and returns a Step result.
              #
              # Subclasses must implement this method to perform the actual check.
              #
              # @return [Status::Step] the result of the check
              # @raise [NotImplementedError] if not implemented by subclass
              def call
                raise NotImplementedError, 'Subclasses must implement #call'
              end

              private

              # @return [Status::Context] the shared context
              attr_reader :context

              # Creates a new Step result.
              #
              # Helper method to create Step instances with less verbosity.
              #
              # @param status [Symbol] the status (:success, :warning, :failure, :halted)
              # @param details [Hash, Array, nil] optional details about the check result
              # @return [Status::Step] a new Step instance
              def step(status, details = nil)
                Step.new(status, details)
              end
            end
          end
        end
      end
    end
  end
end
