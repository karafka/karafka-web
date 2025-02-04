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
              attr_accessor :id
            end

            # @return [Hash]
            attr_reader :params

            # @param params [Hash] command details (if any). Some commands may require extra
            #   details to work. They can be obtained from here.
            def initialize(params)
              @params = params
            end

            private

            # @return [String] current process id
            def process_id
              @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
            end

            # @return [Boolean] Is given process to which a command was sent operating in an
            #   standalone mode. We need to know this, because some commands are prohibited from
            #   being executed in the embedded or swarm processes since there the signaling is
            #   handled differently (either via the main process or supervisor).
            def standalone?
              Karafka::Server.execution_mode == :standalone
            end

            def id
              self.class.id
            end
          end
        end
      end
    end
  end
end
