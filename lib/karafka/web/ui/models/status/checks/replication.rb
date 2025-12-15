# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if topics have adequate replication factors.
            #
            # In production environments, replication factor < 2 is a potential
            # problem because data could be lost if a broker fails. This check
            # warns about low replication but doesn't fail because it's not
            # critical for functionality.
            #
            # @note Low replication is only a warning in production environments.
            #   In non-production environments, replication of 1 is acceptable.
            class Replication < Base
              depends_on :partitions

              class << self
                # @return [Hash] empty hash for halted state
                def halted_details
                  {}
                end
              end

              # Executes the replication check.
              #
              # Verifies that all topics have replication factor >= 2 in production.
              #
              # @return [Status::Step] result with topic details including replication factors
              def call
                details = context.topics_details

                status = :success
                # Low replication is not an error but just a warning and a potential problem
                # in case of a crash, this is why we do not fail but warn only
                status = :warning if details.values.any? { |det| det[:replication] < 2 }
                # Allow for non-production setups to use replication 1 as it is not that relevant
                status = :success unless Karafka.env.production?

                step(status, details)
              end
            end
          end
        end
      end
    end
  end
end
