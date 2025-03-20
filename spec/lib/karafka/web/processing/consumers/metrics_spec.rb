# frozen_string_literal: true

RSpec.describe_current do
  let(:metrics_topic) { Karafka::Web.config.topics.consumers.metrics.name = create_topic }
  let(:fixture) { Fixtures.consumers_metrics_file }

  describe '#current!' do
    subject(:metrics) { described_class.current! }

    before { metrics_topic }

    context 'when there is no current state' do
      let(:expected_error) { ::Karafka::Web::Errors::Processing::MissingConsumersMetricsError }

      it { expect { metrics }.to raise_error(expected_error) }
    end

    context 'when metrics topic does not exist' do
      let(:expected_error) do
        ::Karafka::Web::Errors::Processing::MissingConsumersMetricsTopicError
      end

      before { Karafka::Web.config.topics.consumers.metrics.name = generate_topic_name }

      it { expect { metrics }.to raise_error(expected_error) }
    end

    context 'when current state exists' do
      before { produce(metrics_topic, fixture) }

      it 'expect to get it with the data inside' do
        expect(metrics).to be_a(Hash)
        expect(metrics.key?(:aggregated)).to be(true)
        expect(metrics.key?(:consumer_groups)).to be(true)
        expect(metrics.key?(:schema_version)).to be(true)
        expect(metrics.key?(:dispatched_at)).to be(true)
      end
    end
  end
end
