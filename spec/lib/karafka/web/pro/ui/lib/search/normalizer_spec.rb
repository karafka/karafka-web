# frozen_string_literal: true

RSpec.describe_current do
  describe '.call' do
    let(:search_query) do
      {
        'phrase' => 'test phrase',
        'messages' => '10000',
        'matcher' => 'ExampleMatcher',
        'partitions' => ['partition1', 'partition2', nil, 'partition1'],
        'offset_type' => 'latest',
        'timestamp' => '1627381800',
        'offset' => '0'
      }
    end

    let(:normalized_query) do
      {
        phrase: 'test phrase',
        messages: 10_000,
        matcher: 'ExampleMatcher',
        partitions: %w[partition1 partition2],
        offset_type: 'latest',
        timestamp: 1_627_381_800,
        offset: 0
      }
    end

    it 'returns a normalized hash' do
      expect(described_class.call(search_query)).to eq(normalized_query)
    end

    context 'when partitions contain nil values' do
      before { search_query['partitions'] = ['partition1', nil, 'partition2', nil] }

      it 'removes nil values from partitions' do
        expect(described_class.call(search_query)[:partitions]).to eq(%w[partition1 partition2])
      end
    end

    context 'when partitions contain duplicates' do
      before { search_query['partitions'] = %w[partition1 partition1 partition2] }

      it 'removes duplicate values from partitions' do
        expect(described_class.call(search_query)[:partitions]).to eq(%w[partition1 partition2])
      end
    end

    context 'when phrase is nil' do
      before { search_query['phrase'] = nil }

      it 'casts nil phrase to an empty string' do
        expect(described_class.call(search_query)[:phrase]).to eq('')
      end
    end

    context 'when messages is a non-numeric string' do
      before { search_query['messages'] = 'non-numeric' }

      it 'casts non-numeric messages to 0' do
        expect(described_class.call(search_query)[:messages]).to eq(0)
      end
    end

    context 'when matcher is nil' do
      before { search_query['matcher'] = nil }

      it 'casts nil matcher to an empty string' do
        expect(described_class.call(search_query)[:matcher]).to eq('')
      end
    end

    context 'when offset_type is nil' do
      before { search_query['offset_type'] = nil }

      it 'casts nil offset_type to an empty string' do
        expect(described_class.call(search_query)[:offset_type]).to eq('')
      end
    end

    context 'when timestamp is a non-numeric string' do
      before { search_query['timestamp'] = 'non-numeric' }

      it 'casts non-numeric timestamp to 0' do
        expect(described_class.call(search_query)[:timestamp]).to eq(0)
      end
    end

    context 'when offset is a non-numeric string' do
      before { search_query['offset'] = 'non-numeric' }

      it 'casts non-numeric offset to 0' do
        expect(described_class.call(search_query)[:offset]).to eq(0)
      end
    end
  end
end
