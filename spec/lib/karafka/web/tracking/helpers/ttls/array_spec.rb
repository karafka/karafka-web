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
end
