# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        module Requests
          # @note This class is used internally by the Web UI to wrap controllers
          #   and inject execution hooks around any method call (before/after filters).
          #
          # ExecutionWrapper delegates all method calls to the provided controller instance.
          # Before and after each invocation, it runs the controller's registered hooks.
          #
          # This allows for cleaner separation of concerns and reusable hook logic.
          #
          # @example
          #   controller = SomeController.new
          #   wrapper = ExecutionWrapper.new(controller)
          #   wrapper.call # will run before(:call), call, then after(:call)
          class ExecutionWrapper
            # @param controller [Object] a controller instance responding to method calls
            def initialize(controller)
              @controller = controller
            end

            # Delegates any method call to the controller and wraps it with before/after hooks
            #
            # @param method_name [Symbol] the name of the method being called
            # @return [Object] the result of the delegated controller method for Roda to operate on
            def method_missing(method_name, *, &)
              @controller.run_before_hooks(method_name)
              result = @controller.public_send(method_name, *, &)
              @controller.run_after_hooks(method_name)
              result
            end

            # Properly supports respond_to? checks by delegating to the controller
            #
            # @param method_name [Symbol] the method name to check
            # @param include_private [Boolean] whether to include private methods
            # @return [Boolean] true if controller responds to the method
            def respond_to_missing?(method_name, include_private = false)
              @controller.respond_to?(method_name, include_private)
            end
          end
        end
      end
    end
  end
end
