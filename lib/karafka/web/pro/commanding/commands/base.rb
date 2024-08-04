# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          # Base for all the commands
          class Base
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
          end
        end
      end
    end
  end
end
