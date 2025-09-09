# frozen_string_literal: true

RSpec.describe_current do
  subject(:inflector) { described_class.new(__FILE__) }

  describe '#camelize' do
    context 'when processing regular non-migration files' do
      it 'uses default camelization for regular files' do
        basename = 'some_file'
        abspath = '/lib/karafka/web/some_file.rb'

        expect(inflector.camelize(basename, abspath)).to eq('SomeFile')
      end

      it 'uses default camelization for nested regular files' do
        basename = 'nested_component'
        abspath = '/lib/karafka/web/ui/models/nested_component.rb'

        expect(inflector.camelize(basename, abspath)).to eq('NestedComponent')
      end
    end

    context 'when processing migration files' do
      context 'when in migrations directory with timestamped files' do
        it 'removes timestamp prefix from consumers_metrics migrations' do
          basename = '1699543515_fill_missing_received_and_sent_bytes'
          abspath = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                    '1699543515_fill_missing_received_and_sent_bytes.rb'

          expect(inflector.camelize(basename, abspath)).to eq('FillMissingReceivedAndSentBytes')
        end

        it 'removes timestamp prefix from consumers_states migrations' do
          basename = '1704722380_split_listeners_into_active_and_paused'
          abspath = '/lib/karafka/web/management/migrations/consumers_states/' \
                    '1704722380_split_listeners_into_active_and_paused.rb'

          expect(inflector.camelize(basename, abspath)).to eq('SplitListenersIntoActiveAndPaused')
        end

        it 'handles initial migration files with timestamp 0' do
          basename = '0_set_initial'
          abspath = '/lib/karafka/web/management/migrations/consumers_metrics/0_set_initial.rb'

          expect(inflector.camelize(basename, abspath)).to eq('SetInitial')
        end

        it 'handles complex migration names with underscores' do
          basename = '1706611396_rename_lag_total_to_lag_hybrid'
          abspath = '/lib/karafka/web/management/migrations/consumers_states/' \
                    '1706611396_rename_lag_total_to_lag_hybrid.rb'

          expect(inflector.camelize(basename, abspath)).to eq('RenameLagTotalToLagHybrid')
        end

        it 'handles migration with job-related naming' do
          basename = '1716218393_populate_jobs_metrics'
          abspath = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                    '1716218393_populate_jobs_metrics.rb'

          expect(inflector.camelize(basename, abspath)).to eq('PopulateJobsMetrics')
        end
      end

      context 'when path matches migration pattern but basename does not' do
        it 'uses default camelization for invalid basename format' do
          basename = 'invalid_migration_name'
          abspath = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                    'invalid_migration_name.rb'

          expect(inflector.camelize(basename, abspath)).to eq('InvalidMigrationName')
        end

        it 'uses default camelization for basename without timestamp' do
          basename = 'no_timestamp_migration'
          abspath = '/lib/karafka/web/management/migrations/consumers_states/' \
                    'no_timestamp_migration.rb'

          expect(inflector.camelize(basename, abspath)).to eq('NoTimestampMigration')
        end
      end

      context 'when basename matches migration pattern but path does not' do
        it 'uses default camelization for timestamped files outside migrations' do
          basename = '1699543515_some_regular_file'
          abspath = '/lib/karafka/web/ui/models/1699543515_some_regular_file.rb'

          expect(inflector.camelize(basename, abspath)).to eq('1699543515SomeRegularFile')
        end
      end
    end

    context 'when handling edge cases' do
      it 'processes migration files with different migration directories' do
        basename = '1700000000_test_migration'
        abspath = '/lib/karafka/web/management/migrations/some_other_type/' \
                  '1700000000_test_migration.rb'

        expect(inflector.camelize(basename, abspath)).to eq('TestMigration')
      end

      it 'handles empty migration name after timestamp' do
        basename = '1700000000_'
        abspath = '/lib/karafka/web/management/migrations/consumers_metrics/1700000000_.rb'

        # This would extract empty string, which results in empty class name
        expect(inflector.camelize(basename, abspath)).to eq('')
      end

      it 'handles single character migration names' do
        basename = '1700000000_a'
        abspath = '/lib/karafka/web/management/migrations/consumers_states/1700000000_a.rb'

        expect(inflector.camelize(basename, abspath)).to eq('A')
      end

      it 'handles migration names with numbers' do
        basename = '1700000000_add_field_v2_support'
        abspath = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                  '1700000000_add_field_v2_support.rb'

        expect(inflector.camelize(basename, abspath)).to eq('AddFieldV2Support')
      end
    end

    context 'when validating regex patterns' do
      it 'correctly identifies migration directory paths using class functionality' do
        # Test using the actual camelize method behavior instead of accessing private constants
        valid_migration_basename = '1699543515_test_migration'
        valid_migration_path = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                               '1699543515_test_migration.rb'

        result = inflector.camelize(valid_migration_basename, valid_migration_path)
        expect(result).to eq('TestMigration') # Should strip timestamp
      end

      it 'correctly rejects non-migration directory paths using class functionality' do
        timestamped_basename = '1699543515_not_migration'
        non_migration_path = '/lib/karafka/web/processing/1699543515_not_migration.rb'

        result = inflector.camelize(timestamped_basename, non_migration_path)
        expect(result).to eq('1699543515NotMigration') # Should not strip timestamp
      end

      it 'correctly identifies timestamped basenames using class functionality' do
        valid_basename = '1699543515_test_migration'
        valid_path = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                     '1699543515_test_migration.rb'

        result = inflector.camelize(valid_basename, valid_path)
        expect(result).to eq('TestMigration')
      end

      it 'correctly rejects non-timestamped basenames using class functionality' do
        invalid_basename = 'no_timestamp_migration'
        migration_path = '/lib/karafka/web/management/migrations/consumers_metrics/' \
                         'no_timestamp_migration.rb'

        result = inflector.camelize(invalid_basename, migration_path)
        expect(result).to eq('NoTimestampMigration') # Should use default behavior
      end
    end
  end
end
