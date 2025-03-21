# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          module Consumers
            # Sends a signal to stop the process
            # @note Does not work in an embedded mode because we do not own the Ruby process.
            class Stop < Base
              self.name = 'consumers.stop'

              # Performs the command if not in embedded mode
              def call
                return unless standalone?

                ::Process.kill('QUIT', ::Process.pid)

                result(status: 'applied')
              end
            end
          end
        end
      end
    end
  end
end
