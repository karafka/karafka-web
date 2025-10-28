# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        # Consumer reports migrations
        module ConsumersReports
          # Migrates consumer reports from schema < 1.3.0 that used process[:name] to process[:id]
          #
          # In schema versions 1.2.x and earlier (karafka-web <= v0.8.2), the process identifier
          # was stored in the :name field. Starting with schema 1.3.0 (karafka-web v0.9.0+),
          # this was renamed to :id for consistency.
          #
          # This migration ensures old reports can be processed by current aggregators that
          # expect the :id field.
          class RenameProcessNameToId < Base
            # Apply to all schema versions before 1.3.0
            self.versions_until = '1.3.0'
            self.type = :consumers_reports

            # @param report [Hash] consumer report to migrate
            def migrate(report)
              # If :id already exists, nothing to do (already migrated or newer schema)
              return if report[:process][:id]

              # Rename :name to :id
              # Both :name (in schema < 1.3.0) and :id (in schema >= 1.3.0) were always
              # required fields, so we don't need nil checks for valid reports
              report[:process][:id] = report[:process][:name]
              report[:process].delete(:name)
            end
          end
        end
      end
    end
  end
end
