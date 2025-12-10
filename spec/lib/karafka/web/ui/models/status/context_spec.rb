# frozen_string_literal: true

RSpec.describe_current do
  subject(:context) { described_class.new }

  describe 'accessors' do
    it { expect(context).to respond_to(:cluster_info) }
    it { expect(context).to respond_to(:cluster_info=) }
    it { expect(context).to respond_to(:connection_time) }
    it { expect(context).to respond_to(:connection_time=) }
    it { expect(context).to respond_to(:current_state) }
    it { expect(context).to respond_to(:current_state=) }
    it { expect(context).to respond_to(:current_metrics) }
    it { expect(context).to respond_to(:current_metrics=) }
    it { expect(context).to respond_to(:processes) }
    it { expect(context).to respond_to(:processes=) }
    it { expect(context).to respond_to(:subscriptions) }
    it { expect(context).to respond_to(:subscriptions=) }
  end

  describe '#topics_consumers_states' do
    it 'returns the configured states topic name' do
      expect(context.topics_consumers_states).to eq(
        Karafka::Web.config.topics.consumers.states.name.to_s
      )
    end
  end

  describe '#topics_consumers_reports' do
    it 'returns the configured reports topic name' do
      expect(context.topics_consumers_reports).to eq(
        Karafka::Web.config.topics.consumers.reports.name.to_s
      )
    end
  end

  describe '#topics_consumers_metrics' do
    it 'returns the configured metrics topic name' do
      expect(context.topics_consumers_metrics).to eq(
        Karafka::Web.config.topics.consumers.metrics.name.to_s
      )
    end
  end

  describe '#topics_errors' do
    it 'returns the configured errors topic name' do
      expect(context.topics_errors).to eq(Karafka::Web.config.topics.errors.name)
    end
  end

  describe '#topics_details' do
    context 'when cluster_info is nil' do
      it 'returns topics with default values' do
        details = context.topics_details

        expect(details.keys).to include(context.topics_consumers_states)
        expect(details.keys).to include(context.topics_consumers_reports)
        expect(details.keys).to include(context.topics_consumers_metrics)
        expect(details.keys).to include(context.topics_errors)

        details.each_value do |detail|
          expect(detail[:present]).to be(false)
          expect(detail[:partitions]).to eq(0)
          expect(detail[:replication]).to eq(1)
        end
      end
    end

    context 'when cluster_info has topic data' do
      let(:cluster_info) do
        # cluster_info from ClusterInfo.fetch is an Rdkafka::Metadata object
        # that responds to #topics returning an array of hashes
        Struct.new(:topics).new(
          [
            {
              topic_name: context.topics_consumers_states,
              partition_count: 1,
              partitions: [{ replica_count: 3 }]
            }
          ]
        )
      end

      before { context.cluster_info = cluster_info }

      it 'returns topics with actual values' do
        details = context.topics_details

        expect(details[context.topics_consumers_states][:present]).to be(true)
        expect(details[context.topics_consumers_states][:partitions]).to eq(1)
        expect(details[context.topics_consumers_states][:replication]).to eq(3)
      end
    end

    it 'memoizes the result' do
      first_call = context.topics_details
      second_call = context.topics_details

      expect(first_call).to be(second_call)
    end
  end

  describe '#clear_topics_details_cache' do
    it 'clears the memoized topics_details' do
      first_call = context.topics_details
      context.clear_topics_details_cache
      second_call = context.topics_details

      expect(first_call).not_to be(second_call)
    end
  end
end
