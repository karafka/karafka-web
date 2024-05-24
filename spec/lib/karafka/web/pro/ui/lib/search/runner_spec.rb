# frozen_string_literal: true

RSpec.describe_current do
  subject(:runner) { described_class.new(topic, partitions_count, search_criteria) }

  context 'when using mocked specs' do
    let(:topic) { 'test_topic' }
    let(:partitions_count) { 3 }
    let(:search_criteria) do
      {
        matcher: Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawPayloadIncludes.name,
        limit: 10,
        offset: 0,
        offset_type: 'latest',
        partitions: %w[0 1],
        phrase: 'test phrase',
        timestamp: Time.now.to_i
      }
    end

    let(:matcher_instance) { Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawPayloadIncludes.new }
    let(:iterator_instance) { instance_double('Karafka::Pro::Iterator') }

    let(:message1) do
      instance_double(
        Karafka::Messages::Message,
        partition: 0,
        offset: 0,
        timestamp: Time.now.to_i,
        clean!: nil,
        raw_payload: ''
      )
    end

    let(:message2) do
      instance_double(
        Karafka::Messages::Message,
        partition: 1,
        offset: 1,
        timestamp: Time.now.to_i,
        clean!: nil,
        raw_payload: ''
      )
    end

    before do
      allow(Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawPayloadIncludes)
        .to receive(:new)
        .and_return(matcher_instance)

      allow(Karafka::Pro::Iterator)
        .to receive(:new).and_return(iterator_instance)

      allow(iterator_instance)
        .to receive(:each)
        .and_yield(message1)
        .and_yield(message2)

      allow(iterator_instance)
        .to receive(:stop)

      allow(iterator_instance)
        .to receive(:stop_current_partition)
    end

    describe '#call' do
      it 'returns the matched results and metrics' do
        results, metrics = runner.call

        expect(results).to be_an(Array)
        expect(metrics).to be_a(Hash)
        expect(metrics[:totals]).to be_a(Hash)
        expect(metrics[:partitions]).to be_a(Hash)
      end

      it 'collects the correct metrics' do
        runner.call

        expect(runner.instance_variable_get(:@totals_stats)[:checked]).to eq(2)
        expect(runner.instance_variable_get(:@totals_stats)[:matched]).to eq(0)
      end

      context 'when a message matches the phrase' do
        before do
          allow(matcher_instance).to receive(:call).and_return(true)
        end

        it 'adds the message to the matched results' do
          results, = runner.call

          expect(results.size).to eq(2)
        end
      end

      context 'when the total checked limit reach the limit' do
        let(:search_criteria) { super().merge(limit: 1) }

        before { allow(iterator_instance).to receive(:stop) }

        it 'stops the iterator' do
          runner.call

          expect(iterator_instance).to have_received(:stop).at_least(:once)
        end
      end

      context 'when the checked limit for a partition reach the limit' do
        let(:search_criteria) { super().merge(limit: 2) }

        before { allow(iterator_instance).to receive(:stop_current_partition) }

        it 'stops the current partition in the iterator' do
          runner.call

          expect(iterator_instance).to have_received(:stop_current_partition)
        end
      end
    end
  end

  # Search is also covered with controller specs
  context 'when runningend to end search integrations' do
    let(:partitions_count) { 1 }

    let(:search_criteria) do
      {
        matcher: Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawPayloadIncludes.name,
        limit: 100,
        offset: 0,
        offset_type: 'latest',
        partitions: %w[0 1],
        phrase: 'test phrase',
        timestamp: Time.now.to_i
      }
    end

    context 'when requested topic does not exist' do
      let(:topic) { SecureRandom.uuid }

      it { expect { runner.call }.to raise_error(Rdkafka::RdkafkaError) }
    end

    context 'when topic exists but we want to search in a higher partition' do
      let(:topic) { create_topic }
      let(:partitions_count) { 1 }

      it { expect(runner.call.first).to eq([]) }
    end

    context 'when we want to search in many partitions and all include some data' do
      let(:topic) { create_topic(partitions: 2) }
      let(:partitions_count) { 2 }

      before do
        produce(topic, '12 test phrase 12', partition: 0)
        produce(topic, '12 test phrase 12', partition: 1)
        produce(topic, 'na', partition: 0)
        produce(topic, 'na', partition: 1)
      end

      it { expect(runner.call.first.size).to eq(2) }
    end

    context 'when we want to search in one partition and others have data' do
      let(:topic) { create_topic(partitions: 2) }
      let(:partitions_count) { 2 }

      before do
        produce(topic, '12 test phrase 12', partition: 1)
        produce(topic, 'na', partition: 0)
        produce(topic, 'na', partition: 1)

        search_criteria[:partitions][0]
      end

      it { expect(runner.call.first.size).to eq(1) }
    end

    context 'when we want to search from beginning but what we want is ahead of our limits' do
      let(:topic) { create_topic }

      before do
        20.times { produce(topic, 'na') }

        produce(topic, '12 test phrase 12', partition: 0)

        search_criteria[:limit] = 10
        search_criteria[:offset_type] = 'offset'
        search_criteria[:offset] = 0
      end

      it { expect(runner.call.first.size).to eq(0) }
    end

    context 'when we want to search from beginning on many and divided does not reach' do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          12.times { produce(topic, 'na', partition: partition) }
          produce(topic, '12 test phrase 12', partition: partition)
        end

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = 'offset'
        search_criteria[:offset] = 0
        search_criteria[:partitions] = %w[all]
      end

      it { expect(runner.call.first.size).to eq(0) }
    end

    context 'when we want to search from beginning on many and divided reaches' do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, '12 test phrase 12', partition: partition)
        end

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = 'offset'
        search_criteria[:offset] = 0
        search_criteria[:partitions] = %w[all]
      end

      it { expect(runner.call.first.size).to eq(10) }
    end

    context 'when searching with offset ahead of searched limit' do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, '12 test phrase 12', partition: partition)
        end

        sleep(1)

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = 'timestamp'
        search_criteria[:timestamp] = Time.now.to_i
        search_criteria[:partitions] = %w[all]
      end

      it { expect(runner.call.first.size).to eq(0) }
    end

    context 'when searching with offset behind of searched limit' do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, '12 test phrase 12', partition: partition)
        end

        sleep(1)

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = 'timestamp'
        search_criteria[:timestamp] = Time.now.to_i - 100
        search_criteria[:partitions] = %w[all]
      end

      it { expect(runner.call.first.size).to eq(10) }
    end
  end
end
