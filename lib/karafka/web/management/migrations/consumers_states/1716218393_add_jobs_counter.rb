# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersStates
          # Adds the jobs counter matching batches
          class AddJobsCounter < Base
            self.versions_until = '1.4.0'
            self.type = :consumers_states

            # @param state [Hash]
            def migrate(state)
              # If missing we copy-paste from batches as the closest matching value.
              # Since batch always has a job, this is a good starting point
              state[:stats][:jobs] = state[:stats][:batches]
            end
          end
        end
      end
    end
  end
end
