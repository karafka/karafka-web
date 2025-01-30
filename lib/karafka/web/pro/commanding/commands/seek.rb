# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          # Topic partition seek command request handler
          class Seek < Base
            # Dispatches the seek request into the appropriate filter and indicates that the
            # seeking is in an acceptance state
            def call
              # Publish back info on who did this with all the details for inspection
              Dispatcher.acceptance(params, process_id, 'seek')
            end
          end
        end
      end
    end
  end
end
