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

  describe '#config' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/config/#{SecureRandom.uuid}" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting configs of an existing topic' do
      before { get "topics/config/#{topic}" }

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

  describe '#replication' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/replication/#{SecureRandom.uuid}" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting replication of an existing topic' do
      before { get "topics/replication/#{topic}" }

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

  describe '#distribution' do
    let(:no_data_msg) { 'Those partitions are empty and do not contain any data' }
    let(:many_partitions_msg) { 'distribution results are computed based only' }

    context 'when trying to read distribution of a non-existing topic' do
      before { get "topics/distribution/#{SecureRandom.uuid}" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting distribution of an existing empty topic' do
      before { get "topics/distribution/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing empty topic with multiple partitions' do
      let(:partitions) { 100 }

      before { get "topics/distribution/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with one partition and data' do
      before do
        produce_many(topic, Array.new(100, ''))
        get "topics/distribution/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('100.0%')
        expect(body).not_to include(no_data_msg)
      end
    end

    context 'when getting distribution of an existing topic with few partitions and data' do
      let(:partitions) { 5 }

      before do
        5.times { |i| produce_many(topic, Array.new(100, ''), partition: i) }

        get "topics/distribution/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('20.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).not_to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of an existing topic with many partitions and data' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/distribution/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end

    context 'when getting distribution of a topic with many partitions and data page 2' do
      let(:partitions) { 100 }

      before do
        100.times { |i| produce_many(topic, Array.new(10, ''), partition: i) }

        get "topics/distribution/#{topic}?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('chartjs-bar')
        expect(body).to include(topic)
        expect(body).to include('4.0%')
        expect(body).to include('<td>25</td>')
        expect(body).not_to include(no_data_msg)
        expect(body).to include(many_partitions_msg)
      end
    end
  end
end
