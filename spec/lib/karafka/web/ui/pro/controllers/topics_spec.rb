# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:removed_or_compacted) { 'This offset does not contain any data.' }
  let(:internal_topic) { "__#{SecureRandom.uuid}" }

  describe '#index' do
    before do
      create_topic(topic_name: internal_topic)
      get 'topics'
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).to include(topics_config.consumers.states)
      expect(body).to include(topics_config.consumers.metrics)
      expect(body).to include(topics_config.consumers.reports)
      expect(body).to include(topics_config.errors)
      expect(body).not_to include(internal_topic)
    end

    context 'when there are no topics' do
      before do
        allow(::Karafka::Web::Ui::Models::Topic).to receive(:all).and_return([])
        get 'topics'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('There are no available topics in the current cluster')
      end
    end

    context 'when internal topics should be displayed' do
      before do
        allow(::Karafka::Web.config.ui.visibility)
          .to receive(:internal_topics)
          .and_return(true)

        get 'topics'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topics_config.consumers.states)
        expect(body).to include(topics_config.consumers.metrics)
        expect(body).to include(topics_config.consumers.reports)
        expect(body).to include(topics_config.errors)
        expect(body).to include(internal_topic)
      end
    end
  end

  describe '#configs' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/configs/#{SecureRandom.uuid}" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting configs of an existing topic' do
      before { get "topics/configs/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('max.message.bytes')
        expect(body).to include('retention.ms')
        expect(body).to include('min.insync.replicas')
      end
    end
  end

  describe '#partitions' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/partitions/#{SecureRandom.uuid}" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting partitions of an existing topic' do
      before { get "topics/partitions/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topic)
        expect(body).to include('Replica count')
        expect(body).to include('In sync brokers')
      end
    end
  end
end
