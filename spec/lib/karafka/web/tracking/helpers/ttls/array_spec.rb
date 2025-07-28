# frozen_string_literal: true

RSpec.describe_current do
  subject(:ttl_array) { described_class.new(100) }

  context 'when the array is empty' do
    it { expect(ttl_array.to_a).to eq([]) }
  end

  context 'when we have one element before ttl' do
    before { ttl_array << 1 }

    it { expect(ttl_array.to_a).to eq([1]) }
  end

  context 'when we have pre and post ttl elements' do
    before do
      ttl_array << 1
      sleep(0.1)
      ttl_array << 2
    end

    it { expect(ttl_array.to_a).to eq([2]) }
  end

  context 'when we had only ttled elements' do
    before do
      ttl_array << 1
      sleep(0.1)
    end

    it { expect(ttl_array).to be_empty }
  end

  context 'when testing samples method' do
    it 'returns empty array when no elements' do
      expect(ttl_array.samples).to eq([])
    end

    it 'returns hash with value and added_at for elements within ttl' do
      ttl_array << 1
      samples = ttl_array.samples

      expect(samples.size).to eq(1)
      expect(samples.first[:value]).to eq(1)
      expect(samples.first[:added_at]).to be_a(Float)
    end

    it 'returns only samples within ttl window' do
      ttl_array << 1
      sleep(0.05)
      ttl_array << 2
      sleep(0.05)

      samples = ttl_array.samples
      expect(samples.size).to eq(1)
      expect(samples.first[:value]).to eq(2)
    end

    it 'maintains chronological order of samples' do
      ttl_array << 1
      ttl_array << 2
      ttl_array << 3

      samples = ttl_array.samples
      expect(samples.map { |s| s[:value] }).to eq([1, 2, 3])
    end
  end

  describe '#inspect' do
    let(:ttl) { 1000 }
    let(:array) { described_class.new(ttl) }

    it 'returns correct format for empty array' do
      result = array.inspect

      expect(result).to match(/^#<Karafka::Web::Tracking::Helpers::Ttls::Array:0x[0-9a-f]+ ttl=1000ms size=0>$/)
    end

    it 'returns correct format with items' do
      array << 'item1'
      array << 'item2'

      result = array.inspect

      expect(result).to match(/^#<Karafka::Web::Tracking::Helpers::Ttls::Array:0x[0-9a-f]+ ttl=1000ms size=2>$/)
    end

    it 'shows correct TTL value' do
      custom_array = described_class.new(5000)

      expect(custom_array.inspect).to include('ttl=5000ms')
    end

    it 'shows current size after expired items are cleared' do
      # Add items that will expire
      allow(array).to receive(:monotonic_now).and_return(1000)
      array << 'old_item'

      # Time passes beyond TTL
      allow(array).to receive(:monotonic_now).and_return(3000)
      array << 'new_item'

      result = array.inspect

      expect(result).to include('size=1') # Only new_item should remain
    end

    it 'includes object_id in hexadecimal format' do
      result = array.inspect
      object_id_hex = format('%#x', array.object_id)

      expect(result).to include(object_id_hex)
    end

    it 'calls clear before inspection' do
      allow(array).to receive(:clear).and_call_original
      array.inspect
      expect(array).to have_received(:clear)
    end

    it 'handles thread safety during concurrent modifications' do
      errors = []

      writer = Thread.new do
        50.times { |i| array << "item_#{i}" }
      rescue StandardError => e
        errors << e
      end

      inspector = Thread.new do
        20.times do
          result = array.inspect
          expect(result).to be_a(String)
          expect(result).to include('ttl=1000ms')
        end
      rescue StandardError => e
        errors << e
      end

      [writer, inspector].each(&:join)
      expect(errors).to be_empty
    end
  end
end
