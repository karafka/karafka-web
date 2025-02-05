# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Partitions
            class Resume < Base
              self.id = 'partitions.resume'

              # Dispatches the seek request into the appropriate filter and indicates that the
              # seeking is in an acceptance state
              def call
                Handlers::Partitions::Tracker.instance << params

                # Publish back info on who did this with all the details for inspection
                Dispatcher.acceptance(params, process_id, id)
              end
            end
          end
        end
      end
    end
  end
end
