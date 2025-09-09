# frozen_string_literal: true

RSpec.describe_current do
  subject(:aggregator) { described_class.new }

  let(:report1) do
    {
      process: { id: 'process-1' },
      dispatched_at: Time.now.to_f - 10
    }
  end

  let(:report2) do
    {
      process: { id: 'process-2' },
      dispatched_at: Time.now.to_f - 5
    }
  end

  let(:report3) do
    {
      process: { id: 'process-1' },
      dispatched_at: Time.now.to_f
    }
  end

  describe '#initialize' do
    it 'initializes with empty active reports hash' do
      expect(aggregator.instance_variable_get(:@active_reports)).to eq({})
    end

    it 'includes time helpers' do
      expect(aggregator).to respond_to(:monotonic_now)
      expect(aggregator).to respond_to(:float_now)
    end
  end

  describe '#add' do
    it 'adds a report to active reports' do
      aggregator.add(report1)

      active_reports = aggregator.instance_variable_get(:@active_reports)
      expect(active_reports['process-1']).to eq(report1)
    end

    it 'updates existing process report with newer data' do
      aggregator.add(report1)
      aggregator.add(report3)

      active_reports = aggregator.instance_variable_get(:@active_reports)
      expect(active_reports['process-1']).to eq(report3)
    end

    it 'stores multiple process reports' do
      aggregator.add(report1)
      aggregator.add(report2)

      active_reports = aggregator.instance_variable_get(:@active_reports)
      expect(active_reports).to include('process-1' => report1)
      expect(active_reports).to include('process-2' => report2)
    end

    it 'updates aggregated_from timestamp to the latest dispatch time' do
      aggregator.add(report1)
      expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(report1[:dispatched_at])

      aggregator.add(report2)
      expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(report2[:dispatched_at])

      aggregator.add(report3)
      expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(report3[:dispatched_at])
    end

    it 'handles multiple reports with different dispatch times correctly' do
      # Add reports in mixed order
      aggregator.add(report2) # middle time
      aggregator.add(report1) # oldest time
      aggregator.add(report3) # newest time

      # Should use the latest dispatch time regardless of addition order
      expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(report3[:dispatched_at])
    end
  end

  describe 'time handling' do
    context 'when dealing with lagged reports' do
      it 'uses dispatch time from reports instead of real time for aggregation' do
        older_time = Time.now.to_f - 100
        older_report = { process: { id: 'old-process' }, dispatched_at: older_time }

        aggregator.add(older_report)

        expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(older_time)
      end
    end

    context 'when reports arrive out of order' do
      it 'always uses the maximum dispatch time for aggregated_from' do
        future_time = Time.now.to_f + 10
        past_time = Time.now.to_f - 10
        present_time = Time.now.to_f

        future_report = { process: { id: 'future' }, dispatched_at: future_time }
        past_report = { process: { id: 'past' }, dispatched_at: past_time }
        present_report = { process: { id: 'present' }, dispatched_at: present_time }

        # Add in chronological order
        aggregator.add(past_report)
        aggregator.add(present_report)
        aggregator.add(future_report)

        expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(future_time)

        # Add another past report - shouldn't change aggregated_from
        another_past = { process: { id: 'another-past' }, dispatched_at: past_time - 5 }
        aggregator.add(another_past)

        expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(future_time)
      end
    end
  end

  describe 'inheritance and modularity' do
    it 'is designed to be inherited by specific aggregators' do
      child_class = Class.new(described_class) do
        def custom_method
          'custom functionality'
        end
      end

      child_instance = child_class.new
      expect(child_instance).to respond_to(:add)
      expect(child_instance.custom_method).to eq('custom functionality')
    end

    it 'provides access to active reports for child classes' do
      aggregator.add(report1)
      aggregator.add(report2)

      active_reports = aggregator.instance_variable_get(:@active_reports)
      expect(active_reports.size).to eq(2)
      expect(active_reports.keys).to contain_exactly('process-1', 'process-2')
    end
  end

  describe 'edge cases' do
    context 'when adding reports with identical dispatch times' do
      let(:same_time) { Time.now.to_f }
      let(:report_a) { { process: { id: 'a' }, dispatched_at: same_time } }
      let(:report_b) { { process: { id: 'b' }, dispatched_at: same_time } }

      it 'handles identical dispatch times correctly' do
        aggregator.add(report_a)
        aggregator.add(report_b)

        expect(aggregator.instance_variable_get(:@aggregated_from)).to eq(same_time)
      end
    end

    context 'when process reports are updated multiple times' do
      it 'only keeps the latest report per process' do
        aggregator.add(report1)
        aggregator.add(report3) # Same process ID, newer dispatch time

        active_reports = aggregator.instance_variable_get(:@active_reports)
        expect(active_reports.size).to eq(1)
        expect(active_reports['process-1']).to eq(report3)
      end
    end
  end
end
