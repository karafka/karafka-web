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
                features.commanding!

                request(
                  Commanding::Commands::Consumers::Trace,
                  process_id
                )

                redirect(
                  :back,
                  success: dispatched_to_one(:trace, process_id)
                )
              end

              # Dispatches the quiet request to a given process
              #
              # @param process_id [String]
              def quiet(process_id)
                features.commanding!

                request(
                  Commanding::Commands::Consumers::Quiet,
                  process_id
                )

                redirect(
                  :back,
                  success: dispatched_to_one(:quiet, process_id)
                )
              end

              # Dispatches the stop request to a given process
              #
              # @param process_id [String]
              def stop(process_id)
                features.commanding!

                request(
                  Commanding::Commands::Consumers::Stop,
                  process_id
                )

                redirect(
                  :back,
                  success: dispatched_to_one(:stop, process_id)
                )
              end

              # Dispatches the quiet request that should trigger on all consumers
              def quiet_all
                features.commanding!

                request(
                  Commanding::Commands::Consumers::Quiet,
                  '*'
                )

                redirect(
                  :back,
                  success: dispatched_to_all(:quiet)
                )
              end

              # Dispatches the stop request that should trigger on all consumers
              def stop_all
                features.commanding!

                request(
                  Commanding::Commands::Consumers::Stop,
                  '*'
                )

                redirect(
                  :back,
                  success: dispatched_to_all(:stop)
                )
              end

              private

              # Dispatches given command
              # @param command [Class] command class
              # @param process_id [String] process id or '*' for all processes
              def request(command, process_id)
                matchers = process_id == '*' ? {} : { process_id: process_id }

                Commanding::Dispatcher.request(
                  command.name,
                  {},
                  matchers: matchers
                )
              end

              # @param process_id [String] find given process
              def find_process(process_id)
                Models::Process.find(
                  Models::ConsumersState.current!,
                  process_id
                )
              end

              # Generates a nice flash message about the dispatch
              # @param name [Symbol]
              # @param process_id [String]
              # @return [String] flash message that command has been dispatched to a given process
              def dispatched_to_one(name, process_id)
                command_name = name.to_s.capitalize

                format_flash(
                  'The ? command has been dispatched to the ? process',
                  command_name,
                  process_id
                )
              end

              # Generates a nice flash message about dispatch of multi-process command
              # @param name [Symbol]
              # @return [String] flash message that command has been dispatched
              def dispatched_to_all(name)
                command_name = name.to_s.capitalize

                format_flash(
                  'The ? command has been dispatched to ? active processes',
                  command_name,
                  'all'
                )
              end
            end
          end
        end
      end
    end
  end
end
