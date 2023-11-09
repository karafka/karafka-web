# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Migrator used to run migrations on the states topics
      # There are cases during upgrades, where extra fields may be added and other data, so in
      # order not to deal with cases of some information missing, we can just migrate the data
      # and ensure all the fields that we require after upgrade are present
      class Migrator
        # Migrations that we want to run (if applicable)
        MIGRATIONS = [
          Migrations::FillMissingReceivedAndSentBytesInStates,
          Migrations::FillMissingReceivedAndSentBytesInMetrics
        ].sort_by(&:created_at).freeze

        class << self
          # Picks needed data from Kafka, alters it with migrations and puts the updated data
          # back into Kafka. This ensures, that our Web UI topics that hold aggregated data are
          # always aligned with the Web UI expectations
          #
          # @note To simplify things we always migrate and update all the topics data even if only
          #   part was migrated. That way we always ensure that all the elements are up to date
          def call
            consumers_metrics = Consumers::Metrics.current!,
            consumers_states = Consumers::State.current!
            any_migrations = false

            MIGRATIONS.each do |migration_class|
              data = case migration_class.type
                     when :consumers_metrics
                       consumers_metrics
                     when :consumers_states
                       consumers_states
                     else
                       raise ::Karafka::Errors::UnsupportedCaseError, migration_class.type
                     end

              next if data[:schema_version] >= migration_class.versions_until

              migration_class.new.migrate(data)

              any_migrations = true
            end

            consumers_states[:schema_version] = Consumers::Aggregators::State::SCHEMA_VERSION
            consumers_metrics[:schema_version] = Consumers::Aggregators::Metrics::SCHEMA_VERSION

            return unless any_migrations

            Publisher.call(
              consumers_states,
              consumers_metrics
            )
          end
        end
      end
    end
  end
end
