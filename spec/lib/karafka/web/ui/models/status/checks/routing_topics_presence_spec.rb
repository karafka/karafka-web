# frozen_string_literal: true

RSpec.describe_current do
  subject(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe 'DSL configuration' do
    it { expect(described_class.independent?).to be(false) }
    it { expect(described_class.dependency).to eq(:consumers_reports_schema_state) }
    it { expect(described_class.halted_details).to eq([]) }
  end

  describe '#call' do
    let(:existing_topics) { %w[topic1 topic2 topic3] }

    before do
      context.cluster_info = Struct.new(:topics).new(
        existing_topics.map { |name| { topic_name: name } }
      )
    end

    context 'when all routed topics exist in cluster' do
      let(:topic) do
        double('Topic', name: 'topic1', active?: true).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        double('TopicsCollection').tap do |tc|
          allow(tc).to receive(:map).and_yield(topic).and_return([topic])
        end
      end

      let(:consumer_group) do
        double('ConsumerGroup', topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it 'returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details).to be_empty
      end
    end

    context 'when some routed topics are missing from cluster' do
      let(:missing_topic) do
        double('Topic', name: 'missing_topic', active?: true).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        double('TopicsCollection').tap do |tc|
          allow(tc).to receive(:map).and_yield(missing_topic).and_return([missing_topic])
        end
      end

      let(:consumer_group) do
        double('ConsumerGroup', topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it 'returns warning' do
        result = check.call

        expect(result.status).to eq(:warning)
        expect(result.success?).to be(true)
      end

      it 'includes missing topics in details' do
        result = check.call

        expect(result.details).to include('missing_topic')
      end
    end

    context 'when topic is a pattern topic' do
      let(:pattern_topic) do
        double('Topic', name: 'pattern_topic', active?: true, patterns?: true).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(true)
        end
      end

      let(:topics_collection) do
        double('TopicsCollection').tap do |tc|
          allow(tc).to receive(:map).and_yield(pattern_topic).and_return([pattern_topic])
        end
      end

      let(:consumer_group) do
        double('ConsumerGroup', topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it 'ignores pattern topics and returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details).to be_empty
      end
    end

    context 'when topic is inactive' do
      let(:inactive_topic) do
        double('Topic', name: 'inactive_topic', active?: false).tap do |t|
          allow(t).to receive(:respond_to?).with(:patterns?).and_return(false)
        end
      end

      let(:topics_collection) do
        double('TopicsCollection').tap do |tc|
          allow(tc).to receive(:map).and_yield(inactive_topic).and_return([inactive_topic])
        end
      end

      let(:consumer_group) do
        double('ConsumerGroup', topics: topics_collection)
      end

      before do
        allow(Karafka::App).to receive(:routes).and_return([consumer_group])
      end

      it 'ignores inactive topics and returns success' do
        result = check.call

        expect(result.status).to eq(:success)
        expect(result.details).to be_empty
      end
    end
  end
end
