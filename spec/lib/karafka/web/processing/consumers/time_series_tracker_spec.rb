# frozen_string_literal: true

RSpec.describe_current do
  subject(:built) { described_class.new(existing, {}) }

  let(:empty_stats) do
    {
      batches: 0,
      messages: 0,
      retries: 0,
      dead: 0,
      busy: 0,
      enqueued: 0,
      threads_count: 0,
      processes: 0,
      rss: 0,
      listeners_count: 0,
      utilization: 0,
      lag_stored: 0
    }
  end

  let(:days) do
    empty_stats.dup.tap do |stat|
      stat[:batches] = 5
      stat[:messages] = 10
    end
  end

  let(:hours) do
    empty_stats.dup.tap do |stat|
      stat[:batches] = 2
      stat[:messages] = 23
    end
  end

  let(:minutes) do
    empty_stats.dup.tap do |stat|
      stat[:batches] = 12
      stat[:messages] = 122
    end
  end

  let(:seconds) do
    empty_stats.dup.tap do |stat|
      stat[:batches] = 2
      stat[:messages] = 33
    end
  end

  context 'when aggregated_state is empty' do
    let(:aggregated_state) { {} }

    it { expect { built }.to raise_error(KeyError) }
  end

  context 'when there are empty initial stats' do
    let(:aggregated_state) { { stats: stats } }
    let(:stats) { empty_stats }

    let(:last_time) { built.to_h[:days].first.first }

    it 'expect days to fill with one sample and empty defaults' do
      expect(built.to_h[:days]).to eq([[last_time, stats]])
    end

    it 'expect hours to fill with one sample and empty defaults' do
      expect(built.to_h[:hours]).to eq([[last_time, stats]])
    end

    it 'expect minutes to fill with one sample and empty defaults' do
      expect(built.to_h[:minutes]).to eq([[last_time, stats]])
    end

    it 'expect seconds to fill with one sample and empty defaults' do
      expect(built.to_h[:seconds]).to eq([[last_time, stats]])
    end
  end

  context 'when we had some historicals long ago present and non-empty current' do
    let(:aggregated_state) { { stats: stats, historicals: historicals } }

    let(:stats) do
      empty_stats.dup.tap do |stat|
        stat[:batches] = 2
        stat[:messages] = 100
      end
    end

    let(:historicals) do
      {
        days: [[1_689_099_896, days]],
        hours: [[1_689_099_896, hours]],
        minutes: [[1_689_099_896, minutes]],
        seconds: [[1_689_099_896, seconds]]
      }
    end

    let(:last_time) { built.to_h[:days].first.first }

    it 'expect days to fill with a new sample and preserve historicals' do
      expect(built.to_h[:days].size).to eq(2)
      expect(built.to_h[:days].last.last).to eq(stats)
      expect(built.to_h[:days].first.last).to eq(historicals[:days].first.last)
    end

    it 'expect hours to fill with a new sample and preserve historicals' do
      expect(built.to_h[:hours].size).to eq(2)
      expect(built.to_h[:hours].last.last).to eq(stats)
      expect(built.to_h[:hours].first.last).to eq(historicals[:hours].first.last)
    end

    it 'expect minutes to fill with a new sample and preserve historicals' do
      expect(built.to_h[:minutes].size).to eq(2)
      expect(built.to_h[:minutes].last.last).to eq(stats)
      expect(built.to_h[:minutes].first.last).to eq(historicals[:minutes].first.last)
    end

    it 'expect seconds to fill with a new sample and preserve historicals' do
      expect(built.to_h[:seconds].size).to eq(2)
      expect(built.to_h[:seconds].last.last).to eq(stats)
      expect(built.to_h[:seconds].first.last).to eq(historicals[:seconds].first.last)
    end
  end

  context 'when we have several historicals for the same range' do
    let(:aggregated_state) { { stats: stats, historicals: historicals } }

    let(:stats) do
      empty_stats.dup.tap do |stat|
        stat[:batches] = 2
        stat[:messages] = 100
      end
    end

    let(:close_time) { 1_689_099_896 - 1 }

    let(:historicals) do
      {
        days: [[1_689_099_896, days], [close_time, days]],
        hours: [[1_689_099_896, hours], [close_time, hours]],
        minutes: [[1_689_099_896, minutes], [close_time, minutes]],
        seconds: [[1_689_099_896, seconds], [close_time, seconds]]
      }
    end

    it 'expect days to fill with a new sample and preserve historicals' do
      expect(built.to_h[:days].size).to eq(2)
      expect(built.to_h[:days].last.last).to eq(stats)
      expect(built.to_h[:days].first.last).to eq(historicals[:days].first.last)
    end

    it 'expect hours to fill with a new sample and preserve historicals' do
      expect(built.to_h[:hours].size).to eq(2)
      expect(built.to_h[:hours].last.last).to eq(stats)
      expect(built.to_h[:hours].first.last).to eq(historicals[:hours].first.last)
    end

    it 'expect minutes to fill with a new sample and preserve historicals' do
      expect(built.to_h[:minutes].size).to eq(2)
      expect(built.to_h[:minutes].last.last).to eq(stats)
      expect(built.to_h[:minutes].first.last).to eq(historicals[:minutes].first.last)
    end

    it 'expect seconds to fill with a new sample and preserve historicals' do
      expect(built.to_h[:seconds].size).to eq(2)
      expect(built.to_h[:seconds].last.last).to eq(stats)
      expect(built.to_h[:seconds].first.last).to eq(historicals[:seconds].first.last)
    end
  end
end
