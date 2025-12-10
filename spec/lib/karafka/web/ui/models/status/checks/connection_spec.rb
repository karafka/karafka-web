# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:enabled) }
    it { expect(described_class.halted_details).to eq({ time: nil }) }
  end

  describe '#call' do
    context 'when connection is fast' do
      let(:cluster_info) { Struct.new(:topics).new([]) }

      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo).to receive(:fetch).and_return(cluster_info)
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details[:time]).to be_a(Numeric)
        expect(result.details[:time]).to be < 1_000
      end

      it 'caches cluster_info in context' do
        check.call

        expect(context.cluster_info).not_to be_nil
        expect(context.connection_time).not_to be_nil
      end
    end

    context 'when connection fails' do
      before do
        allow(Karafka::Web::Ui::Models::ClusterInfo)
          .to receive(:fetch)
          .and_raise(Rdkafka::RdkafkaError.new(0))
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.details[:time]).to eq(1_000_000)
      end
    end

    context 'when already connected (cached)' do
      before do
        context.connection_time = 500
        context.cluster_info = Struct.new(:topics).new([])
      end

      it 'does not connect again' do
        allow(Karafka::Web::Ui::Models::ClusterInfo).to receive(:fetch)

        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details[:time]).to eq(500)
        expect(Karafka::Web::Ui::Models::ClusterInfo).not_to have_received(:fetch)
      end
    end
  end
end
