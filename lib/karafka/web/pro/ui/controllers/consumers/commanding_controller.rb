# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Controller responsible for handling requests that should trigger some action on the
            # consumers.
            class CommandingController < BaseController
              # Dispatches the trace request to a given process
              #
              # @param process_id [String]
              def trace(process_id)
                command(:trace, process_id)

                redirect(
                  :back,
                  success: dispatched_to_one(:trace, process_id)
                )
              end

              # Dispatches the quiet request to a given process
              #
              # @param process_id [String]
              def quiet(process_id)
                command(:quiet, process_id)

                redirect(
                  :back,
                  success: dispatched_to_one(:quiet, process_id)
                )
              end

              # Dispatches the stop request to a given process
              #
              # @param process_id [String]
              def stop(process_id)
                command(:stop, process_id)

                redirect(
                  :back,
                  success: dispatched_to_one(:stop, process_id)
                )
              end

              # Dispatches the quiet request that should trigger on all consumers
              def quiet_all
                command(:quiet, '*')

                redirect(
                  :back,
                  success: dispatched_to_all(:quiet)
                )
              end

              # Dispatches the stop request that should trigger on all consumers
              def stop_all
                command(:stop, '*')

                redirect(
                  :back,
                  success: dispatched_to_all(:stop)
                )
              end

              private

              # Dispatches given command
              # @param command [Symbol] command
              # @param process_id [String] process id
              def command(command, process_id)
                Commanding::Dispatcher.command("consumers.#{command}", process_id)
              end

              # @param process_id [String] find given process
              def find_process(process_id)
                Models::Process.find(
                  Models::ConsumersState.current!,
                  process_id
                )
              end

              # Generates a nice flash message about the dispatch
              # @param command [Symbol]
              # @param process_id [String]
              # @return [String] flash message that command has been dispatched to a given process
              def dispatched_to_one(command, process_id)
                command_name = command.to_s.capitalize

                "The #{command_name} command has been dispatched to the #{process_id} process."
              end

              # Generates a nice flash message about dispatch of multi-process command
              # @param command [Symbol]
              # @return [String] flash message that command has been dispatched
              def dispatched_to_all(command)
                command_name = command.to_s.capitalize

                "The #{command_name} command has been dispatched to all active processes."
              end
            end
          end
        end
      end
    end
  end
end
