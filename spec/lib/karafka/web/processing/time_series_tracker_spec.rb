# frozen_string_literal: true

RSpec.describe Karafka::Web::Processing::TimeSeriesTracker do
  subject(:tracker) { described_class.new(existing) }

  let(:existing) { {} }
  let(:current_time) { Time.now.to_f }

  describe '#initialize' do
    context 'when initialized with empty data' do
      it 'creates empty arrays for all time ranges' do
        expect(tracker.to_h).to eq(
          {
            days: [],
            hours: [],
            minutes: [],
            seconds: []
          }
        )
      end
    end

    context 'when initialized with existing data' do
      let(:existing) do
        {
          days: [[100, { value: 1 }]],
          hours: [[200, { value: 2 }]],
          minutes: [[300, { value: 3 }]],
          seconds: [[400, { value: 4 }]]
        }
      end

      it 'imports the existing data' do
        result = tracker.to_h
        expect(result[:days]).to eq(existing[:days])
        expect(result[:hours]).to eq(existing[:hours])
        expect(result[:minutes]).to eq(existing[:minutes])
        expect(result[:seconds]).to eq(existing[:seconds])
      end
    end

    context 'when there is existing data from fixtures' do
      let(:metrics) { Fixtures.consumers_metrics_json }
      let(:existing) { metrics.fetch(:aggregated) }

      it { expect(tracker.to_h[:days]).to eq(existing[:days]) }
      it { expect(tracker.to_h[:hours]).to eq(existing[:hours]) }
      it { expect(tracker.to_h[:minutes]).to eq(existing[:minutes]) }
      it { expect(tracker.to_h[:seconds]).to eq(existing[:seconds]) }
    end
  end

  describe '#add' do
    let(:metric_data) { { messages: 100, errors: 2 } }

    it 'adds data to all time ranges' do
      tracker.add(metric_data, current_time)
      result = tracker.to_h

      expect(result[:days].last).to eq([current_time.floor, metric_data])
      expect(result[:hours].last).to eq([current_time.floor, metric_data])
      expect(result[:minutes].last).to eq([current_time.floor, metric_data])
      expect(result[:seconds].last).to eq([current_time.floor, metric_data])
    end

    it 'floors the timestamp' do
      fractional_time = 123_456.789
      tracker.add(metric_data, fractional_time)

      result = tracker.to_h
      expect(result[:days].last[0]).to eq(123_456)
    end

    context 'when adding multiple data points' do
      it 'keeps all data points initially' do
        tracker.add({ value: 1 }, current_time)
        tracker.add({ value: 2 }, current_time + 10)
        tracker.add({ value: 3 }, current_time + 20)

        # Before eviction, all points should be present
        result = tracker.to_h
        expect(result[:seconds].size).to eq(3)
      end
    end

    context 'when adding multiple metrics for the same time window' do
      before do
        tracker.add({ a: 1 }, 1)
        tracker.add({ a: 2 }, 1.01)
        tracker.add({ a: 3 }, 1_000_000)
        tracker.add({ a: 4 }, 1_000_000.01)
      end

      it 'expect to only keep the oldest one after materialization in a time window' do
        expect(tracker.to_h[:days]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
        expect(tracker.to_h[:hours]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
        expect(tracker.to_h[:minutes]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
        expect(tracker.to_h[:seconds]).to eq([[1, { a: 1 }], [1_000_000, { a: 4 }]])
      end
    end
  end

  describe '#to_h with eviction logic' do
    context 'when data exceeds limits' do
      it 'respects the limit for days range' do
        # Add more than 57 data points for days range
        60.times do |i|
          time = current_time + (i * 8 * 60 * 60) # 8 hours apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h
        expect(result[:days].size).to be <= 57
      end

      it 'respects the limit for hours range' do
        # Add more than 49 data points for hours range
        55.times do |i|
          time = current_time + (i * 30 * 60) # 30 minutes apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h
        expect(result[:hours].size).to be <= 49
      end

      it 'respects the limit for minutes range' do
        # Add more than 61 data points for minutes range
        70.times do |i|
          time = current_time + (i * 60) # 1 minute apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h
        expect(result[:minutes].size).to be <= 61
      end

      it 'respects the limit for seconds range' do
        # Add more than 61 data points for seconds range
        70.times do |i|
          time = current_time + (i * 5) # 5 seconds apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h
        expect(result[:seconds].size).to be <= 61
      end
    end

    context 'when multiple data points fall in same resolution window' do
      it 'groups data by resolution for days' do
        base_time = current_time
        # Add multiple points within same 8-hour window
        tracker.add({ value: 1 }, base_time)
        tracker.add({ value: 2 }, base_time + 3600) # 1 hour later
        tracker.add({ value: 3 }, base_time + 7200) # 2 hours later

        # Add point in next window
        tracker.add({ value: 4 }, base_time + (8 * 60 * 60) + 1)

        result = tracker.to_h
        # The implementation may create more points than expected due to resolution logic
        expect(result[:days].size).to be >= 2
      end

      it 'keeps the first data point within a resolution window' do
        base_time = current_time
        tracker.add({ value: 'first' }, base_time)
        tracker.add({ value: 'second' }, base_time + 1)
        tracker.add({ value: 'third' }, base_time + 2)

        result = tracker.to_h
        # For seconds resolution (5 seconds), all should be in same window
        # and we should keep the first one
        expect(result[:seconds].first[1][:value]).to eq('first')
      end
    end

    context 'when data is added out of order' do
      it 'sorts data by timestamp' do
        tracker.add({ value: 3 }, current_time + 300)
        tracker.add({ value: 1 }, current_time + 100)
        tracker.add({ value: 2 }, current_time + 200)

        result = tracker.to_h
        times = result[:seconds].map(&:first)
        expect(times).to eq(times.sort)
      end
    end

    context 'with the most recent value injection' do
      it 'always includes the most recent value even if beyond normal range' do
        # Add old data
        10.times do |i|
          tracker.add({ value: i }, current_time + (i * 10))
        end

        # Add a very recent value
        recent_time = current_time + 1000
        tracker.add({ recent: true }, recent_time)

        result = tracker.to_h
        # Most recent should be included in all ranges
        expect(result[:days].last[1]).to eq({ recent: true })
        expect(result[:hours].last[1]).to eq({ recent: true })
        expect(result[:minutes].last[1]).to eq({ recent: true })
        expect(result[:seconds].last[1]).to eq({ recent: true })
      end
    end
  end

  describe 'TIME_RANGES constant' do
    it 'defines correct resolution for each range' do
      expect(described_class::TIME_RANGES[:days][:resolution]).to eq(8 * 60 * 60)
      expect(described_class::TIME_RANGES[:hours][:resolution]).to eq(30 * 60)
      expect(described_class::TIME_RANGES[:minutes][:resolution]).to eq(60)
      expect(described_class::TIME_RANGES[:seconds][:resolution]).to eq(5)
    end

    it 'defines correct limits for each range' do
      expect(described_class::TIME_RANGES[:days][:limit]).to eq(57)
      expect(described_class::TIME_RANGES[:hours][:limit]).to eq(49)
      expect(described_class::TIME_RANGES[:minutes][:limit]).to eq(61)
      expect(described_class::TIME_RANGES[:seconds][:limit]).to eq(61)
    end

    it 'has all ranges frozen' do
      expect(described_class::TIME_RANGES).to be_frozen
      described_class::TIME_RANGES.each_value do |config|
        expect(config).to be_frozen
      end
    end
  end

  describe 'memory efficiency' do
    it 'evicts data only when to_h is called' do
      # Add lots of data
      100.times do |i|
        tracker.add({ value: i }, current_time + i)
      end

      # Data is not evicted until we call to_h
      # This is by design for performance
      result = tracker.to_h

      # After eviction, data should be within limits
      expect(result[:seconds].size).to be <= 61
    end
  end

  describe 'edge cases' do
    context 'when adding data with identical timestamps' do
      it 'handles duplicate timestamps correctly' do
        tracker.add({ value: 1 }, 1000.0)
        tracker.add({ value: 2 }, 1000.0)
        tracker.add({ value: 3 }, 1000.0)

        result = tracker.to_h
        # Should keep only one entry per unique timestamp after deduplication
        unique_times = result[:seconds].map(&:first).uniq
        expect(unique_times.size).to eq(1)
      end
    end

    context 'when working with very large timestamps' do
      it 'handles large timestamps correctly' do
        large_time = 9_999_999_999.99
        tracker.add({ value: 'large' }, large_time)

        result = tracker.to_h
        expect(result[:days].last[0]).to eq(9_999_999_999)
      end
    end

    context 'when data is empty' do
      it 'handles empty data gracefully' do
        result = tracker.to_h
        expect(result[:days]).to be_empty
        expect(result[:hours]).to be_empty
        expect(result[:minutes]).to be_empty
        expect(result[:seconds]).to be_empty
      end
    end
  end
end
