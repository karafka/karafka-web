# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Commands
          module Topics
            # Delegates the topic resume request into the topic changes tracker and dispatches the
            # acceptance message back to Kafka. This command resumes all partitions of a given topic
            # within a specific consumer group. It broadcasts to all processes (key='*') and each
            # process determines which partitions it owns for the target consumer group.
            class Resume < Base
              self.name = 'topics.resume'

              # Dispatches the resume request into the appropriate handler and indicates that the
              # resuming is in an acceptance state
              def call
                Handlers::Topics::Tracker.instance << command

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
