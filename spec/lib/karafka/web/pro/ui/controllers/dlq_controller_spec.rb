# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:uuid) { SecureRandom.uuid }

  before { Karafka::Web.config.ui.dlq_patterns = [/#{uuid}-dlq/] }

  describe '#index' do
    context 'when there are no dlq topics' do
      before { get 'dlq' }

      it do
        expect(response).to be_ok
        expect(body).to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are dlq topics' do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { Karafka::App.consumer_groups.last.topics.first.name }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when defined DLQ name matches the topic name with a postfix' do
      let(:topic) { Karafka::App.consumer_groups.first.topics.first }
      let(:dlq_topic) { "#{topic.name}.dql" }

      before do
        allow(topic.dead_letter_queue).to receive(:topic).and_return(dlq_topic)

        create_topic(topic_name: dlq_topic)

        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include("#{topic.name}\"")
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are topics matching the DLQ auto-discovery' do
      let(:topic) { create_topic(topic_name: uuid) }
      let(:dlq_topic) { create_topic(topic_name: "#{uuid}-dlq") }

      before do
        topic
        dlq_topic
        get 'dlq'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(dlq_topic)
        expect(body).not_to include('No Dead Letter Queue topics exist in Kafka')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include("#{uuid}\"")
      end
    end
  end
end
