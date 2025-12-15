# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.
module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          # Base for all the commands
          class Base
            class << self
              attr_accessor :name
            end

            # @return [Hash]
            attr_reader :command

            # @param command [Command] command details (if any). Some commands may require extra
            #   details to work. They can be obtained from here.
            def initialize(command)
              @command = command
            end

            # Executes the command after receiving it.
            def call
              raise NotImlementedError, 'Please implement in a subclass'
            end

            private

            # Dispatches the acceptance message back to Kafka as a confirmation
            #
            # @param params [Hash] hash with the acceptance message details
            def acceptance(params)
              Dispatcher.acceptance(self.class.name, process_id, params)
            end

            # Dispatches the result message back to Kafka with execution details
            #
            # @param params [Hash] hash with the result message details
            def result(params)
              Dispatcher.result(self.class.name, process_id, params)
            end

            # @return [Boolean] Is given process to which a command was sent operating in an
            #   standalone mode. We need to know this, because some commands are prohibited from
            #   being executed in the embedded or swarm processes since there the signaling is
            #   handled differently (either via the main process or supervisor).
            def standalone?
              Karafka::Server.execution_mode.standalone?
            end

            # @return [String] id of the current consumer process
            def process_id
              ::Karafka::Web.config.tracking.consumers.sampler.process_id
            end
          end
        end
      end
    end
  end
end
