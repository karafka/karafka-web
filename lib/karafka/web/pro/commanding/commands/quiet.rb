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
          # Sends a signal to quiet the consumer
          # @note Does not work in an embedded mode because we do not own the Ruby process.
          class Quiet < Base
            # Performs the command if not in embedded mode
            def call
              return unless standalone?

              ::Process.kill('TSTP', ::Process.pid)
            end
          end
        end
      end
    end
  end
end
