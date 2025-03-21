# frozen_string_literal: true

RSpec.describe_current do
  subject(:cache) { described_class.new(ttl_ms) }

  let(:ttl_ms) { 200 }

  describe '#fetch' do
    context 'when key is not cached yet' do
      it 'computes and caches the value' do
        value = cache.fetch(:foo) { 'bar' }
        expect(value).to eq('bar')
        expect(cache.exist?).to be true
      end
    end

    context 'when key is already cached' do
      before { cache.fetch(:foo) { 'first' } }

      it 'returns the cached value without recomputing' do
        result = cache.fetch(:foo) { 'second' }
        expect(result).to eq('first')
      end
    end

    it 'updates the hash after fetching a new key' do
      expect { cache.fetch(:foo) { 'bar' } }.to change(cache, :hash)
    end
  end

  describe '#exist?' do
    it 'returns false before any fetch' do
      expect(cache.exist?).to be false
    end

    it 'returns true after a fetch' do
      cache.fetch(:foo) { 1 }
      expect(cache.exist?).to be true
    end
  end

  describe '#timestamp' do
    it 'returns nil initially' do
      expect(cache.timestamp).to be_nil
    end

    it 'returns a Unix timestamp after fetch' do
      cache.fetch(:foo) { 123 }
      expect(cache.timestamp).to be_a(Numeric)
    end
  end

  describe '#hash' do
    it 'returns nil initially' do
      expect(cache.hash).to be_nil
    end

    it 'returns a SHA256 digest after fetch' do
      cache.fetch(:a) { 1 }
      expect(cache.hash).to match(/\A\h{64}\z/)
    end
  end

  describe '#clear' do
    before { cache.fetch(:foo) { 'bar' } }

    it 'clears values and metadata' do
      cache.clear
      expect(cache.exist?).to be false
      expect(cache.timestamp).to be_nil
      expect(cache.hash).to be_nil
    end
  end

  describe '#clear_if_needed' do
    let(:ts) { Time.now.to_i }

    context 'when session hash and timestamp match current state' do
      it 'does not clear the cache' do
        value = cache.fetch(:foo) { 'bar' }
        result = cache.clear_if_needed(cache.hash, cache.timestamp)
        expect(result).to be_nil
        expect(cache.fetch(:foo) { 'new' }).to eq(value)
      end
    end

    context 'when session timestamp is newer' do
      it 'clears the cache' do
        cache.fetch(:foo) { 'old' }
        expect(
          cache.clear_if_needed('other', cache.timestamp + 10)
        ).to be_nil
        expect(cache.exist?).to be false
      end
    end

    context 'when cache TTL is exceeded' do
      it 'clears the cache' do
        freeze_time = Time.now
        allow(Time).to receive(:now).and_return(freeze_time)

        cache.fetch(:foo) { 'data' }
        initial_ts = cache.timestamp

        # Simulate time passing beyond TTL
        later = freeze_time + ((ttl_ms + 50) / 1000.0)
        allow(Time).to receive(:now).and_return(later)

        cache.clear_if_needed(cache.hash, initial_ts)

        expect(cache.exist?).to be false
      end
    end

    context 'when session hash is nil' do
      it 'clears the cache' do
        cache.fetch(:foo) { 123 }
        cache.clear_if_needed(nil, cache.timestamp)
        expect(cache.exist?).to be false
      end
    end

    context 'when session timestamp is nil' do
      it 'clears the cache' do
        cache.fetch(:foo) { 123 }
        cache.clear_if_needed(cache.hash, nil)
        expect(cache.exist?).to be false
      end
    end
  end
end
