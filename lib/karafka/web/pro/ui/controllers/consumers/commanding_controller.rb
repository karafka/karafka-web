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

                broadcast_request(Commanding::Commands::Consumers::Quiet)

                redirect(
                  :back,
                  success: dispatched_to_all(:quiet)
                )
              end

              # Dispatches the stop request that should trigger on all consumers
              def stop_all
                features.commanding!

                broadcast_request(Commanding::Commands::Consumers::Stop)

                redirect(
                  :back,
                  success: dispatched_to_all(:stop)
                )
              end

              private

              # Dispatches given command to a specific process
              # @param command [Class] command class
              # @param process_id [String] process id
              def request(command, process_id)
                Commanding::Dispatcher.request(
                  command.name,
                  {},
                  matchers: { process_id: process_id }
                )
              end

              # Dispatches given command to all processes (no matchers)
              # @param command [Class] command class
              def broadcast_request(command)
                Commanding::Dispatcher.request(
                  command.name,
                  {},
                  matchers: {}
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
                  "The ? command has been dispatched to the ? process",
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
                  "The ? command has been dispatched to ? active processes",
                  command_name,
                  "all"
                )
              end
            end
          end
        end
      end
    end
  end
end
