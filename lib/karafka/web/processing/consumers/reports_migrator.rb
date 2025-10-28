# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Migrator for consumer reports that applies per-message transformations
        #
        # Unlike the Management::Migrator which operates on aggregated states,
        # this migrator runs on each individual consumer report as it's processed.
        #
        # This is necessary because:
        #   - Reports are continuously published during upgrades
        #   - Reports are short-lived (TTL-based) and don't need persistent migrations
        #   - Old schema reports may remain in Kafka topics for extended periods
        #
        # Migrations are lightweight transformations that normalize old report formats
        # to work with current processing code. Migrations are stored in
        # lib/karafka/web/management/migrations/consumers_reports/ alongside other migrations.
        class ReportsMigrator
          # Applies all applicable migrations to a consumer report
          #
          # @param report [Hash] deserialized consumer report
          # @return [Hash] the same report object, potentially modified in-place
          def call(report)
            # Apply each applicable migration in order
            migrations.each do |migration_class|
              next unless migration_class.applicable?(report[:schema_version])

              migration_class.new.migrate(report)
            end

            report
          end

          private

          # Lazy-initialized cache of report migrations
          # Only computed when first needed to avoid memory overhead if no old reports exist
          def migrations
            @migrations ||= Management::Migrations::Base
                            .sorted_descendants
                            .select { |migration_class| migration_class.type == :consumers_reports }
          end
        end
      end
    end
  end
end
