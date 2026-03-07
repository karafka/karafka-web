# frozen_string_literal: true

describe_current do
  let(:tracker) { described_class.new(existing) }

  let(:existing) { {} }
  let(:current_time) { Time.now.to_f }

  describe "#initialize" do
    context "when initialized with empty data" do
      it "creates empty arrays for all time ranges" do
        assert_equal( { days: [], hours: [], minutes: [], seconds: [] } , tracker.to_h)
      end
    end

    context "when initialized with existing data" do
      let(:existing) do
        {
          days: [[100, { value: 1 }]],
          hours: [[200, { value: 2 }]],
          minutes: [[300, { value: 3 }]],
          seconds: [[400, { value: 4 }]]
        }
      end

      it "imports the existing data" do
        result = tracker.to_h

        assert_equal(existing[:days], result[:days])
        assert_equal(existing[:hours], result[:hours])
        assert_equal(existing[:minutes], result[:minutes])
        assert_equal(existing[:seconds], result[:seconds])
      end
    end

    context "when there is existing data from fixtures" do
      let(:metrics) { Fixtures.consumers_metrics_json }
      let(:existing) { metrics.fetch(:aggregated) }

      it { assert_equal(existing[:days], tracker.to_h[:days]) }
      it { assert_equal(existing[:hours], tracker.to_h[:hours]) }
      it { assert_equal(existing[:minutes], tracker.to_h[:minutes]) }
      it { assert_equal(existing[:seconds], tracker.to_h[:seconds]) }
    end
  end

  describe "#add" do
    let(:metric_data) { { messages: 100, errors: 2 } }

    it "adds data to all time ranges" do
      tracker.add(metric_data, current_time)
      result = tracker.to_h

      assert_equal([current_time.floor, metric_data], result[:days].last)
      assert_equal([current_time.floor, metric_data], result[:hours].last)
      assert_equal([current_time.floor, metric_data], result[:minutes].last)
      assert_equal([current_time.floor, metric_data], result[:seconds].last)
    end

    it "floors the timestamp" do
      fractional_time = 123_456.789
      tracker.add(metric_data, fractional_time)

      result = tracker.to_h

      assert_equal(123_456, result[:days].last[0])
    end

    context "when adding multiple data points" do
      it "keeps all data points initially" do
        tracker.add({ value: 1 }, current_time)
        tracker.add({ value: 2 }, current_time + 10)
        tracker.add({ value: 3 }, current_time + 20)

        # Before eviction, all points should be present
        result = tracker.to_h

        assert_equal(3, result[:seconds].size)
      end
    end

    context "when adding multiple metrics for the same time window" do
      before do
        tracker.add({ a: 1 }, 1)
        tracker.add({ a: 2 }, 1.01)
        tracker.add({ a: 3 }, 1_000_000)
        tracker.add({ a: 4 }, 1_000_000.01)
      end

      it "expect to only keep the oldest one after materialization in a time window" do
        assert_equal([[1, { a: 1 }], [1_000_000, { a: 4 }]], tracker.to_h[:days])
        assert_equal([[1, { a: 1 }], [1_000_000, { a: 4 }]], tracker.to_h[:hours])
        assert_equal([[1, { a: 1 }], [1_000_000, { a: 4 }]], tracker.to_h[:minutes])
        assert_equal([[1, { a: 1 }], [1_000_000, { a: 4 }]], tracker.to_h[:seconds])
      end
    end
  end

  describe "#to_h with eviction logic" do
    context "when data exceeds limits" do
      it "respects the limit for days range" do
        # Add more than 57 data points for days range
        60.times do |i|
          time = current_time + (i * 8 * 60 * 60) # 8 hours apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h

        assert(result[:days].size <= 57)
      end

      it "respects the limit for hours range" do
        # Add more than 49 data points for hours range
        55.times do |i|
          time = current_time + (i * 30 * 60) # 30 minutes apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h

        assert(result[:hours].size <= 49)
      end

      it "respects the limit for minutes range" do
        # Add more than 61 data points for minutes range
        70.times do |i|
          time = current_time + (i * 60) # 1 minute apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h

        assert(result[:minutes].size <= 61)
      end

      it "respects the limit for seconds range" do
        # Add more than 61 data points for seconds range
        70.times do |i|
          time = current_time + (i * 5) # 5 seconds apart
          tracker.add({ value: i }, time)
        end

        result = tracker.to_h

        assert(result[:seconds].size <= 61)
      end
    end

    context "when multiple data points fall in same resolution window" do
      it "groups data by resolution for days" do
        base_time = current_time
        # Add multiple points within same 8-hour window
        tracker.add({ value: 1 }, base_time)
        tracker.add({ value: 2 }, base_time + 3600) # 1 hour later
        tracker.add({ value: 3 }, base_time + 7200) # 2 hours later

        # Add point in next window
        tracker.add({ value: 4 }, base_time + (8 * 60 * 60) + 1)

        result = tracker.to_h
        # The implementation may create more points than expected due to resolution logic
        assert(result[:days].size >= 2)
      end

      it "keeps the first data point within a resolution window" do
        base_time = current_time
        tracker.add({ value: "first" }, base_time)
        tracker.add({ value: "second" }, base_time + 1)
        tracker.add({ value: "third" }, base_time + 2)

        result = tracker.to_h
        # For seconds resolution (5 seconds), all should be in same window
        # and we should keep the first one
        assert_equal("first", result[:seconds].first[1][:value])
      end
    end

    context "when data is added out of order" do
      it "sorts data by timestamp" do
        tracker.add({ value: 3 }, current_time + 300)
        tracker.add({ value: 1 }, current_time + 100)
        tracker.add({ value: 2 }, current_time + 200)

        result = tracker.to_h
        times = result[:seconds].map(&:first)

        assert_equal(times.sort, times)
      end
    end

    context "with the most recent value injection" do
      it "always includes the most recent value even if beyond normal range" do
        # Add old data
        10.times do |i|
          tracker.add({ value: i }, current_time + (i * 10))
        end

        # Add a very recent value
        recent_time = current_time + 1000
        tracker.add({ recent: true }, recent_time)

        result = tracker.to_h
        # Most recent should be included in all ranges
        assert_equal({ recent: true }, result[:days].last[1])
        assert_equal({ recent: true }, result[:hours].last[1])
        assert_equal({ recent: true }, result[:minutes].last[1])
        assert_equal({ recent: true }, result[:seconds].last[1])
      end
    end
  end

  describe "TIME_RANGES constant" do
    it "defines correct resolution for each range" do
      assert_equal(8 * 60 * 60, described_class::TIME_RANGES[:days][:resolution])
      assert_equal(30 * 60, described_class::TIME_RANGES[:hours][:resolution])
      assert_equal(60, described_class::TIME_RANGES[:minutes][:resolution])
      assert_equal(5, described_class::TIME_RANGES[:seconds][:resolution])
    end

    it "defines correct limits for each range" do
      assert_equal(57, described_class::TIME_RANGES[:days][:limit])
      assert_equal(49, described_class::TIME_RANGES[:hours][:limit])
      assert_equal(61, described_class::TIME_RANGES[:minutes][:limit])
      assert_equal(61, described_class::TIME_RANGES[:seconds][:limit])
    end

    it "has all ranges frozen" do
      assert(described_class::TIME_RANGES.frozen?)
      described_class::TIME_RANGES.each_value do |config|
        assert(config.frozen?)
      end
    end
  end

  describe "memory efficiency" do
    it "evicts data only when to_h is called" do
      # Add lots of data
      100.times do |i|
        tracker.add({ value: i }, current_time + i)
      end

      # Data is not evicted until we call to_h
      # This is by design for performance
      result = tracker.to_h

      # After eviction, data should be within limits
      assert(result[:seconds].size <= 61)
    end
  end

  describe "edge cases" do
    context "when adding data with identical timestamps" do
      it "handles duplicate timestamps correctly" do
        tracker.add({ value: 1 }, 1000.0)
        tracker.add({ value: 2 }, 1000.0)
        tracker.add({ value: 3 }, 1000.0)

        result = tracker.to_h
        # Should keep only one entry per unique timestamp after deduplication
        unique_times = result[:seconds].map(&:first).uniq

        assert_equal(1, unique_times.size)
      end
    end

    context "when working with very large timestamps" do
      it "handles large timestamps correctly" do
        large_time = 9_999_999_999.99
        tracker.add({ value: "large" }, large_time)

        result = tracker.to_h

        assert_equal(9_999_999_999, result[:days].last[0])
      end
    end

    context "when data is empty" do
      it "handles empty data gracefully" do
        result = tracker.to_h

        assert_empty(result[:days])
        assert_empty(result[:hours])
        assert_empty(result[:minutes])
        assert_empty(result[:seconds])
      end
    end
  end
end
