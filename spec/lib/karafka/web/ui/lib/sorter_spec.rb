# frozen_string_literal: true

RSpec.describe_current do
  subject(:sorting) do
    described_class
      .new(sort_query, allowed_attributes: allowed_attributes)
      .call(resource)

    resource
  end

  let(:allowed_attributes) { %w[] }

  context 'when we try to sort on something not allowed' do
    let(:resource) { [[1], [2], [3]] }
    let(:sort_query) { 'clear desc' }
    let(:allowed_attributes) { %w[] }

    it { expect { sorting }.not_to change { resource } }
  end

  context 'when we sort array of values in an asc order' do
    let(:resource) { [5, 4, 3, 2, 1] }
    let(:sort_query) { 'itself asc' }
    let(:allowed_attributes) { %w[itself] }

    it { expect(sorting).to eq([1, 2, 3, 4, 5]) }
  end

  context 'when we sort array of values in an desc order' do
    let(:resource) { [1, 2, 3, 4, 5] }
    let(:sort_query) { 'itself desc' }
    let(:allowed_attributes) { %w[itself] }

    it { expect(sorting).to eq([5, 4, 3, 2, 1]) }
  end

  context 'when resource is of not homogeneous type' do
    let(:resource) { [1, 3, 2, true, 'test'] }
    let(:sort_query) { 'itself desc' }
    let(:allowed_attributes) { %w[itself] }

    it 'expect not to sort' do
      expect(sorting).to eq([1, 3, 2, true, 'test'])
    end
  end

  context 'when sorting array of hashes on a symbol key' do
    let(:resource) { [{ a: 2, x: 1 }, { a: 3 }, { a: 7 }] }
    let(:sort_query) { 'a desc' }
    let(:allowed_attributes) { %w[a] }

    it { expect(sorting).to eq([{ a: 7 }, { a: 3 }, { a: 2, x: 1 }]) }
  end

  context 'when sorting array of hashes on a string key' do
    let(:resource) { [{ 'a' => 2, x: 1 }, { 'a' => 3 }, { 'a' => 7 }] }
    let(:sort_query) { 'a desc' }
    let(:allowed_attributes) { %w[a] }

    it { expect(sorting).to eq([{ 'a' => 7 }, { 'a' => 3 }, { 'a' => 2, x: 1 }]) }
  end

  context 'when sorting booleans' do
    let(:resource) { [true, false, true, false] }
    let(:sort_query) { 'itself desc' }
    let(:allowed_attributes) { %w[itself] }

    it { expect(sorting).to eq([true, true, false, false]) }
  end

  context 'when sorting objects that respond to an attribute' do
    let(:resource) { [OpenStruct.new(a: 5), OpenStruct.new(a: 4), OpenStruct.new(a: 3)] }
    let(:sort_query) { 'a asc' }
    let(:allowed_attributes) { %w[a] }

    it do
      expect(sorting).to eq([OpenStruct.new(a: 3), OpenStruct.new(a: 4), OpenStruct.new(a: 5)])
    end
  end

  context 'when sorting objects that do not respond to an attribute' do
    let(:resource) { [OpenStruct.new(x: 5), OpenStruct.new(x: 4), OpenStruct.new(x: 3)] }
    let(:sort_query) { 'a asc' }
    let(:allowed_attributes) { %w[a] }

    it { expect { sorting }.not_to change { resource } }
  end
end
