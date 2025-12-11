# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if required Web UI topics have the correct number of partitions.
            #
            # The consumers states, reports, and metrics topics must have exactly
            # 1 partition each for the Web UI to function correctly. The errors
            # topic can have any number of partitions.
            class Partitions < Base
              depends_on :topics

              class << self
                # @return [Hash] empty hash for halted state
                def halted_details
                  {}
                end
              end

              # Executes the partitions check.
              #
              # Verifies that state, reports, and metrics topics have exactly 1 partition.
              #
              # @return [Status::Step] result with topic details including partition counts
              def call
                details = context.topics_details

                status = :success
                status = :failure if details[context.topics_consumers_states][:partitions] != 1
                status = :failure if details[context.topics_consumers_reports][:partitions] != 1
                status = :failure if details[context.topics_consumers_metrics][:partitions] != 1

                step(status, details)
              end
            end
          end
        end
      end
    end
  end
end
