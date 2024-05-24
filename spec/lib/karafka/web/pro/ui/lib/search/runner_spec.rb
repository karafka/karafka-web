# frozen_string_literal: true

RSpec.describe_current do
  subject(:runner) { described_class.new(topic, partitions_count, search_criteria) }

  context 'when using mocked specs' do
    let(:topic) { 'test_topic' }
    let(:partitions_count) { 3 }
    let(:search_criteria) do
      {
        matcher: Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawPayloadIncludes.name,
        messages: 10,
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

      context 'when the total checked messages reach the limit' do
        let(:search_criteria) { super().merge(messages: 1) }

        before { allow(iterator_instance).to receive(:stop) }

        it 'stops the iterator' do
          runner.call

          expect(iterator_instance).to have_received(:stop).at_least(:once)
        end
      end

      context 'when the checked messages for a partition reach the limit' do
        let(:search_criteria) { super().merge(messages: 2) }

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
    pending
  end
end
