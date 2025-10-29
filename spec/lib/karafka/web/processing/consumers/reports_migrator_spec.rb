# frozen_string_literal: true

RSpec.describe_current do
  subject(:migrator) { described_class.new }

  describe '#call' do
    context 'when report has an old schema version' do
      let(:report) do
        {
          schema_version: '1.2.9',
          type: 'consumer',
          process: {
            name: 'old-process:1:1',
            status: 'running',
            started_at: Time.now.to_f
          },
          dispatched_at: Time.now.to_f,
          stats: { busy: 0, enqueued: 0 }
        }
      end

      it 'applies applicable migrations' do
        result = migrator.call(report)

        # The Management::Migrations::ConsumersReports::RenameProcessNameToId migration should have run
        expect(result[:process][:id]).to eq('old-process:1:1')
        expect(result[:process]).not_to have_key(:name)
      end

      it 'returns the same report object (modified in-place)' do
        original_object_id = report.object_id

        result = migrator.call(report)

        expect(result.object_id).to eq(original_object_id)
      end

      it 'preserves report structure' do
        migrator.call(report)

        expect(report).to have_key(:schema_version)
        expect(report).to have_key(:type)
        expect(report).to have_key(:process)
        expect(report).to have_key(:dispatched_at)
        expect(report).to have_key(:stats)
      end
    end

    context 'when report has a current schema version' do
      let(:report) do
        {
          schema_version: '1.5.0',
          type: 'consumer',
          process: {
            id: 'current-process:1:1',
            status: 'running',
            started_at: Time.now.to_f
          },
          dispatched_at: Time.now.to_f,
          stats: { busy: 0, enqueued: 0 }
        }
      end

      it 'does not modify the report' do
        original_report = Marshal.load(Marshal.dump(report))

        migrator.call(report)

        expect(report).to eq(original_report)
      end
    end

    context 'when multiple migrations are applicable' do
      let(:report) do
        {
          schema_version: '1.0.0',
          process: {
            name: 'very-old-process:1:1',
            status: 'running'
          },
          dispatched_at: Time.now.to_f
        }
      end

      it 'applies migrations in order' do
        # Currently only one migration exists, but this tests the framework
        result = migrator.call(report)

        expect(result[:process][:id]).to eq('very-old-process:1:1')
      end
    end

    context 'when report schema is between migration versions' do
      let(:report) do
        {
          schema_version: '1.2.5',
          process: {
            name: 'mid-version-process:1:1',
            status: 'running'
          },
          dispatched_at: Time.now.to_f
        }
      end

      it 'applies applicable migrations for that version range' do
        migrator.call(report)

        # Schema 1.2.5 < 1.3.0, so RenameProcessNameToId should apply
        expect(report[:process][:id]).to eq('mid-version-process:1:1')
        expect(report[:process]).not_to have_key(:name)
      end
    end
  end
end
