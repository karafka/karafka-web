# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          # Namespace for commands related to consumers themselves
          module Consumers
            # Sends a signal to quiet the consumer
            # @note Does not work in an embedded mode because we do not own the Ruby process.
            class Quiet < Base
              self.name = 'consumers.quiet'

              # Performs the command if not in embedded mode
              def call
                return unless standalone?

                ::Process.kill('TSTP', ::Process.pid)

                result(status: 'applied')
              end
            end
          end
        end
      end
    end
  end
end
