# frozen_string_literal: true

RSpec.describe_current do
  let(:ttl) { 200 }
  let(:cache) { described_class.new(ttl) }

  describe '#read' do
    context 'when the key exists in the cache' do
      let(:key) { :existing_key }
      let(:value) { 'cached_value' }

      before { cache.write(key, value) }

      it 'returns the cached value' do
        expect(cache.read(key)).to eq(value)
      end
    end

    context 'when the key does not exist in the cache' do
      let(:key) { :non_existing_key }

      it 'returns nil' do
        expect(cache.read(key)).to be_nil
      end
    end

    context 'when the cache TTL expires' do
      let(:key) { :expiring_key }
      let(:value) { 'expiring_value' }

      before do
        cache.write(key, value)
        sleep(ttl / 1000.0 + 0.1) # Wait for cache expiration
      end

      it 'returns nil' do
        expect(cache.read(key)).to be_nil
      end
    end
  end

  describe '#write' do
    let(:key) { :new_key }
    let(:value) { 'new_value' }

    it 'stores the key-value pair in the cache' do
      cache.write(key, value)
      expect(cache.read(key)).to eq(value)
    end
  end

  describe '#fetch' do
    context 'when the key exists in the cache' do
      let(:key) { :existing_key }
      let(:value) { 'cached_value' }

      before { cache.write(key, value) }

      it 'returns the cached value' do
        expect(cache.fetch(key) { 'block_value' }).to eq(value)
      end
    end

    context 'when the key does not exist in the cache' do
      let(:key) { :non_existing_key }
      let(:block_value) { 'block_value' }

      it 'yields the block and stores its result in the cache' do
        expect(cache.fetch(key) { block_value }).to eq(block_value)
        expect(cache.read(key)).to eq(block_value)
      end
    end

    context 'when the cache TTL expires' do
      let(:key) { :expiring_key }
      let(:value) { 'expiring_value' }
      let(:block_value) { 'block_value' }

      before do
        cache.write(key, value)
        sleep(ttl / 1000.0 + 0.1) # Wait for cache expiration
      end

      it 'yields the block and updates the cache' do
        expect(cache.fetch(key) { block_value }).to eq(block_value)
        expect(cache.read(key)).to eq(block_value)
      end
    end
  end
end
