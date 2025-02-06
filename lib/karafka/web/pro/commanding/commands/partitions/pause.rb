# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Partitions
            # Delegates the pause request into the partition changes tracker and dispatches the
            # acceptance message back to Kafka
            class Pause < Base
              self.name = 'partitions.pause'

              def call
                Handlers::Partitions::Tracker.instance << command

                acceptance(command.to_h)
              end
            end
          end
        end
      end
    end
  end
end
