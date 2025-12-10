# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:topics) }
    it { expect(described_class.halted_details).to eq({}) }
  end

  describe '#call' do
    context 'when all topics have correct partition count' do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            { topic_name: context.topics_consumers_states, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_reports, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_metrics, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_errors, partition_count: 5, partitions: [{ replica_count: 1 }] }
          ]
        )
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.success?).to be(true)
      end
    end

    context 'when states topic has wrong partition count' do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            { topic_name: context.topics_consumers_states, partition_count: 5, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_reports, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_metrics, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_errors, partition_count: 1, partitions: [{ replica_count: 1 }] }
          ]
        )
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
        expect(result.success?).to be(false)
      end
    end

    context 'when reports topic has wrong partition count' do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            { topic_name: context.topics_consumers_states, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_reports, partition_count: 3, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_metrics, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_errors, partition_count: 1, partitions: [{ replica_count: 1 }] }
          ]
        )
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
      end
    end

    context 'when metrics topic has wrong partition count' do
      before do
        context.cluster_info = Struct.new(:topics).new(
          [
            { topic_name: context.topics_consumers_states, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_reports, partition_count: 1, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_consumers_metrics, partition_count: 2, partitions: [{ replica_count: 1 }] },
            { topic_name: context.topics_errors, partition_count: 1, partitions: [{ replica_count: 1 }] }
          ]
        )
      end

      it 'returns failure' do
        result = check.call

        expect(result.status).to eq(:failure)
      end
    end
  end
end
