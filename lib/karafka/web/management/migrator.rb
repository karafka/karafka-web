# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Migrator used to run migrations on the states topics
      # There are cases during upgrades, where extra fields may be added and other data, so in
      # order not to deal with cases of some information missing, we can just migrate the data
      # and ensure all the fields that we require after upgrade are present
      class Migrator
        # Picks needed data from Kafka, alters it with migrations and puts the updated data
        # back into Kafka. This ensures, that our Web UI topics that hold aggregated data are
        # always aligned with the Web UI expectations
        #
        # @note To simplify things we always migrate and update all the topics data even if only
        #   part was migrated. That way we always ensure that all the elements are up to date
        def call
          any_migrations = false

          Migrations::Base.sorted_descendants.each do |migration_class|
            data = send(migration_class.type)

            next unless migration_class.applicable?(data[:schema_version])

            migration_class.new.migrate(data)

            any_migrations = true
          end

          consumers_state[:schema_version] = Processing::Consumers::Aggregators::State::SCHEMA_VERSION
          consumers_metrics[:schema_version] = Processing::Consumers::Aggregators::Metrics::SCHEMA_VERSION

          Processing::Publisher.call(
            consumers_state,
            consumers_metrics
          )
        end

        private

        def consumers_state
          @consumers_state ||= Processing::Consumers::State.current!
        end

        def consumers_metrics
          @consumers_metrics ||= Processing::Consumers::Metrics.current!
        end
      end
    end
  end
end
