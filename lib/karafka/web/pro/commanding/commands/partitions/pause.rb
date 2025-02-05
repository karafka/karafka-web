# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Partitions
            class Pause < Base
              self.id = 'partitions.pause'

              def call
                Handlers::Partitions::Tracker.instance << params

                Dispatcher.acceptance(params, process_id, id)
              end
            end
          end
        end
      end
    end
  end
end
