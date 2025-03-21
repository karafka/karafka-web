# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        module Requests
          # Adds before/after hook support for controller methods.
          #
          # This module allows registering callbacks that run before and after
          # any named method (e.g., `call`, `show`) or for all methods.
          #
          # Hooks are inherited from parent controllers, making it easy to
          # define shared behavior across a hierarchy.
          #
          # @example Adding hooks to a controller
          #   class MyController
          #     include Hookable
          #
          #     before(:call) { puts "before call" }
          #     after(:call)  { puts "after call" }
          #
          #     def call
          #       run_before_hooks(:call)
          #       # actual logic
          #       run_after_hooks(:call)
          #     end
          #   end
          module Hookable
            # Hook into class inclusion to extend DSL
            #
            # @param base [Class] the class including this module
            def self.included(base)
              base.extend(ClassMethods)
            end

            # DSL methods for defining and inheriting hooks
            module ClassMethods
              # Inherit parent hooks into subclass
              #
              # @param subclass [Class] the subclass inheriting from base controller
              def inherited(subclass)
                super
                subclass.before_hooks.concat(before_hooks)
                subclass.after_hooks.concat(after_hooks)
              end

              # @return [Array] accumulated before hooks
              def before_hooks
                @before_hooks ||= []
              end

              # @return [Array] accumulated after hooks
              def after_hooks
                @after_hooks ||= []
              end

              # Register a before hook
              #
              # @param actions [Array<Symbol>] optional action names to match (e.g., :call)
              # @param block [Proc]
              # @yield a block to execute before matched actions
              def before(*actions, &block)
                before_hooks << [actions, block]
              end

              # Register an after hook
              #
              # @param actions [Array<Symbol>] optional action names to match (e.g., :call)
              # @param block [Proc]
              # @yield a block to execute after matched actions
              def after(*actions, &block)
                after_hooks << [actions, block]
              end
            end

            # Run all before hooks matching the action
            #
            # @param action_name [Symbol] the method name being invoked
            def run_before_hooks(action_name)
              self.class.before_hooks.each do |actions, block|
                instance_exec(&block) if actions.empty? || actions.include?(action_name)
              end
            end

            # Run all after hooks matching the action
            #
            # @param action_name [Symbol] the method name being invoked
            def run_after_hooks(action_name)
              self.class.after_hooks.each do |actions, block|
                instance_exec(&block) if actions.empty? || actions.include?(action_name)
              end
            end
          end
        end
      end
    end
  end
end
