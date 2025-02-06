# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Partitions
            # Topic partition seek command request handler
            class Seek < Base
              self.name = 'partitions.seek'

              # Dispatches the seek request into the appropriate filter and indicates that the
              # seeking is in an acceptance state
              def call
                Handlers::Partitions::Tracker.instance << command

                # Publish back info on who did this with all the details for inspection
                acceptance(command.to_h)
              end
            end
          end
        end
      end
    end
  end
end
