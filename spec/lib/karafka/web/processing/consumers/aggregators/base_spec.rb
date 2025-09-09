# frozen_string_literal: true

RSpec.describe_current do
  # Create a test class to test the base functionality
  let(:test_aggregator_class) do
    Class.new(described_class) do
      attr_reader :active_reports, :aggregated_from

      # Expose protected methods for testing
      def test_memoize_process_report(report)
        memoize_process_report(report)
      end

      def test_update_aggregated_from
        update_aggregated_from
      end
    end
  end

  subject(:aggregator) { test_aggregator_class.new }

  let(:report1) do
    {
      process: {
        id: 'process-1',
        status: 'running'
      },
      dispatched_at: Time.now.to_f - 10
    }
  end

  let(:report2) do
    {
      process: {
        id: 'process-2',
        status: 'running'
      },
      dispatched_at: Time.now.to_f - 5
    }
  end

  let(:report3) do
    {
      process: {
        id: 'process-3',
        status: 'running'
      },
      dispatched_at: Time.now.to_f
    }
  end

  describe '#initialize' do
    it 'initializes with empty active reports' do
      expect(aggregator.active_reports).to eq({})
    end

    it 'does not set aggregated_from initially' do
      expect(aggregator.aggregated_from).to be_nil
    end
  end

  describe '#add' do
    context 'when adding a single report' do
      it 'stores the report in active_reports' do
        aggregator.add(report1)
        expect(aggregator.active_reports['process-1']).to eq(report1)
      end

      it 'sets aggregated_from to the report dispatch time' do
        aggregator.add(report1)
        expect(aggregator.aggregated_from).to eq(report1[:dispatched_at])
      end
    end

    context 'when adding multiple reports' do
      it 'stores all reports in active_reports' do
        aggregator.add(report1)
        aggregator.add(report2)
        aggregator.add(report3)

        expect(aggregator.active_reports.keys).to contain_exactly('process-1', 'process-2', 'process-3')
      end

      it 'updates aggregated_from to the maximum dispatch time' do
        aggregator.add(report1)
        aggregator.add(report2)
        aggregator.add(report3)

        expect(aggregator.aggregated_from).to eq(report3[:dispatched_at])
      end
    end

    context 'when updating an existing process report' do
      let(:updated_report1) do
        {
          process: {
            id: 'process-1',
            status: 'stopped'
          },
          dispatched_at: Time.now.to_f + 10
        }
      end

      it 'overwrites the existing report' do
        aggregator.add(report1)
        aggregator.add(updated_report1)

        expect(aggregator.active_reports['process-1']).to eq(updated_report1)
        expect(aggregator.active_reports.size).to eq(1)
      end

      it 'updates aggregated_from to the new maximum' do
        aggregator.add(report1)
        aggregator.add(report2)
        aggregator.add(updated_report1)

        expect(aggregator.aggregated_from).to eq(updated_report1[:dispatched_at])
      end
    end
  end

  describe '#memoize_process_report (protected)' do
    it 'stores report by process id' do
      aggregator.test_memoize_process_report(report1)
      expect(aggregator.active_reports['process-1']).to eq(report1)
    end

    it 'overwrites existing report for same process id' do
      aggregator.test_memoize_process_report(report1)

      modified_report = report1.merge(dispatched_at: Time.now.to_f + 100)
      aggregator.test_memoize_process_report(modified_report)

      expect(aggregator.active_reports['process-1']).to eq(modified_report)
    end
  end

  describe '#update_aggregated_from (protected)' do
    context 'when no reports exist' do
      it 'sets aggregated_from to nil when no reports are present' do
        aggregator.test_update_aggregated_from
        expect(aggregator.aggregated_from).to be_nil
      end
    end

    context 'when reports exist' do
      before do
        aggregator.test_memoize_process_report(report1)
        aggregator.test_memoize_process_report(report2)
        aggregator.test_memoize_process_report(report3)
      end

      it 'sets aggregated_from to maximum dispatched_at' do
        aggregator.test_update_aggregated_from
        expect(aggregator.aggregated_from).to eq(report3[:dispatched_at])
      end

      it 'updates correctly when times are not in order' do
        out_of_order_report = {
          process: { id: 'process-4', status: 'running' },
          dispatched_at: Time.now.to_f + 100
        }

        aggregator.test_memoize_process_report(out_of_order_report)
        aggregator.test_update_aggregated_from

        expect(aggregator.aggregated_from).to eq(out_of_order_report[:dispatched_at])
      end
    end
  end

  context 'when handling lag compensation' do
    let(:old_report) do
      {
        process: { id: 'lagged-process', status: 'running' },
        dispatched_at: Time.now.to_f - 3600 # 1 hour ago
      }
    end

    let(:current_report) do
      {
        process: { id: 'current-process', status: 'running' },
        dispatched_at: Time.now.to_f
      }
    end

    it 'uses report time instead of real time for aggregation' do
      aggregator.add(old_report)
      expect(aggregator.aggregated_from).to eq(old_report[:dispatched_at])

      aggregator.add(current_report)
      expect(aggregator.aggregated_from).to eq(current_report[:dispatched_at])
    end

    it 'maintains temporal accuracy during catch-up' do
      # Simulate catching up on old data
      aggregator.add(old_report)
      old_time = aggregator.aggregated_from

      # Even though real time has passed, we use report time
      sleep(0.01)
      aggregator.add(old_report)

      expect(aggregator.aggregated_from).to eq(old_time)
    end
  end
end
