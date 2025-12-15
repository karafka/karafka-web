# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          # Namespace for topic-level command execution within a consumer group context
          module Topics
            # Delegates the topic pause request into the topic changes tracker and dispatches the
            # acceptance message back to Kafka. This command pauses all partitions of a given topic
            # within a specific consumer group. It broadcasts to all processes (key='*') and each
            # process determines which partitions it owns for the target consumer group.
            class Pause < Base
              self.name = 'topics.pause'

              # Delegates the pause request to async handling
              def call
                Handlers::Topics::Tracker.instance << command

                acceptance(command.to_h)
              end
            end
          end
        end
      end
    end
  end
end
