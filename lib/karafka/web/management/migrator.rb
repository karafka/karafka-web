# frozen_string_literal: true

module Karafka
  module Web
    # Namespace for all cross-context management operations that are needed to make sure everything
    # operate as expected.
    module Management
      # Migrator used to run migrations on the states topics
      # There are cases during upgrades, where extra fields may be added and other data, so in
      # order not to deal with cases of some information missing, we can just migrate the data
      # and ensure all the fields that we require after upgrade are present
      #
      # Migrations are similar to the once that are present in Ruby on Rails conceptually.
      #
      # We take our most recent state and we can alter it "in place". The altered result will be
      # passed to the consecutive migrations and then republished back to Kafka. This allows us
      # to manage Web UI aggregated data easily.
      #
      # @note We do not migrate the consumers reports for the following reasons:
      #   - if would be extremely hard to migrate them as they are being published and can be still
      #     published when the migrations are running
      #   - we would have to run migrations on each message
      #   - we already have a mechanism in the processing consumer that skips outdated records for
      #     rolling migrations
      #   - those records are short-lived and the expectation is for the user not to run old and
      #     new consumers together for an extensive period of time
      #
      # @note It will raise an error if we try to run migrations but the schemas we want to operate
      #   are newer. This will prevent us from damaging the data and ensures that we only move
      #   forward with the migrations. This can happen in case of a rolling upgrade, where old
      #   instance that is going to be terminated would get a temporary assignment with already
      #   migrated state.
      class Migrator
        # Include this so we can reference the schema versions easily
        include Processing::Consumers::Aggregators

        # Picks needed data from Kafka, alters it with migrations and puts the updated data
        # back into Kafka. This ensures, that our Web UI topics that hold aggregated data are
        # always aligned with the Web UI expectations
        #
        # @note To simplify things we always migrate and update all the topics data even if only
        #   part was migrated. That way we always ensure that all the elements are up to date
        def call
          ensure_migrable!
          # If migrating returns `false` it means no migrations happened
          migrate && publish
        end

        private

        # Raise an exception if there would be an attempt to run migrations on a newer schema for
        # any states we manage. We can only move forward, so attempt to migrate for example from
        # 1.0.0 to 0.9.0 should be considered and error.
        def ensure_migrable!
          if consumers_states[:schema_version] > State::SCHEMA_VERSION
            raise(
              Errors::Management::IncompatibleSchemaError,
              'consumers state newer than supported'
            )
          end

          if consumers_metrics[:schema_version] > Metrics::SCHEMA_VERSION
            raise(
              Errors::Management::IncompatibleSchemaError,
              'consumers metrics newer than supported'
            )
          end

          true
        end

        # Applies migrations if needed and mutates the in-memory data
        #
        # @return [Boolean] were there any migrations applied
        def migrate
          any_migrations = false

          Migrations::Base.sorted_descendants.each do |migration_class|
            data = send(migration_class.type)

            next unless migration_class.applicable?(data[:schema_version])

            migration_class.new.migrate(data)

            any_migrations = true
          end

          any_migrations
        end

        # Publishes all the states migrated records
        def publish
          consumers_states[:schema_version] = State::SCHEMA_VERSION
          consumers_metrics[:schema_version] = Metrics::SCHEMA_VERSION

          # Migrator may run in the context of the processing consumer prior to any states
          # fetching related to processing. We use sync to make sure, that the following
          # processing related states fetched fetch the new states
          Processing::Publisher.publish!(
            consumers_states,
            consumers_metrics
          )
        end

        # @return [Hash] current consumers states most recent state
        def consumers_states
          @consumers_states ||= Processing::Consumers::State.current!
        end

        # @return [Hash] current consumers metrics most recent state
        def consumers_metrics
          @consumers_metrics ||= Processing::Consumers::Metrics.current!
        end
      end
    end
  end
end
