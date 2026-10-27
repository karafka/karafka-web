# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Command to migrate states data. Useful when we have older schema and need to move forward
        class MigrateStatesData < Base
          # How many times we try to read the states before giving up. Initial states produced
          # just before may not yet be visible to admin reads on a slow cluster
          MAX_ATTEMPTS = 5

          # How long (in seconds) we wait before reading the states again
          BACKOFF = 1

          # Errors that mean the states are not (yet) visible, so we may try again
          RETRYABLE_ERRORS = [
            Errors::Processing::MissingConsumersStateError,
            Errors::Processing::MissingConsumersMetricsError
          ].freeze

          private_constant :MAX_ATTEMPTS, :BACKOFF, :RETRYABLE_ERRORS

          # Runs needed migrations (if any) on the states topics
          def call
            attempt = 0

            begin
              attempt += 1
              Migrator.new.call
            rescue *RETRYABLE_ERRORS
              raise if attempt >= MAX_ATTEMPTS

              sleep(BACKOFF)
              retry
            end
          end
        end
      end
    end
  end
end
