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
end
