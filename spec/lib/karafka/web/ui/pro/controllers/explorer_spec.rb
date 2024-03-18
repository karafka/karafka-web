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
      get 'explorer'
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
        allow(::Karafka::Web::Ui::Models::ClusterInfo).to receive(:topics).and_return([])
        get 'explorer'
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

        get 'explorer'
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

  describe '#topic' do
    context 'when we view topic without any messages' do
      before { get "explorer/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include('This topic is empty and does not contain any data')
        expect(body).to include('total: 1')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view topic with one nil message' do
      before do
        produce_many(topic, [nil])
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include('total: 1')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/5")
        expect(body).to include("#{topic}/0/29")
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/4")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with one partition with transactional data' do
      before do
        produce_many(topic, Array.new(30, '1'), type: :transactional)
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/6")
        expect(body).to include("#{topic}/0/29")
        expect(body).to include(compacted_or_transactional_offset)
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/4")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view last page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}?page=2"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/4")
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/5")
        expect(body).not_to include("#{topic}/0/29")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with many partitions' do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, '1'), partition: i) }
        get "explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)

        partitions.times do |i|
          expect(body).to include("#{topic}/#{i}/29")
          expect(body).to include("#{topic}/#{i}/28")
          expect(body).to include("#{topic}/#{i}/27")
          expect(body).to include("#{topic}/#{i}/26")
          expect(body).to include("#{topic}/#{i}/25")
          expect(body).not_to include("#{topic}/#{i}/24")
          expect(body).not_to include("#{topic}/#{i}/30")
        end

        expect(body).not_to include(support_message)
      end
    end

    context 'when we view last page from a topic with many partitions' do
      let(:partitions) { 5 }

      before do
        partitions.times { |i| produce_many(topic, Array.new(30, '1'), partition: i) }
        get "explorer/#{topic}?page=6"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)

        partitions.times do |i|
          expect(body).to include("#{topic}/#{i}/4")
          expect(body).to include("#{topic}/#{i}/3")
          expect(body).to include("#{topic}/#{i}/2")
          expect(body).to include("#{topic}/#{i}/1")
          expect(body).to include("#{topic}/#{i}/0")
          expect(body).not_to include("#{topic}/#{i}/5")
          expect(body).not_to include("#{topic}/#{i}/6")
        end

        expect(body).not_to include(support_message)
      end
    end

    context 'when we request a page above available elements' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/#{topic}?page=100"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include(no_meaningful_results)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#partition' do
    let(:no_data) { 'This partition is empty and does not contain any data' }

    context 'when given partition does not exist' do
      before { get "explorer/#{topic}/1" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when no data in the given partition' do
      before { get "explorer/#{topic}/0" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_data)
        expect(body).to include('Watermark offsets')
        expect(body).to include('high: 0')
        expect(body).to include('low: 0')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when single result in a given partition is present' do
      before do
        produce(topic, '1')
        get "explorer/#{topic}/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Watermark offsets')
        expect(body).to include('high: 1')
        expect(body).to include('low: 0')
        expect(body).not_to include(no_data)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when only single transactional result in a given partition is present' do
      before do
        produce(topic, '1', type: :transactional)
        get "explorer/#{topic}/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Watermark offsets')
        expect(body).to include('high: 2')
        expect(body).to include('low: 0')
        expect(body).not_to include(no_data)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when compacted results are present in a partition' do
      before do
        produce(topic, '1')

        allow(Karafka::Web::Ui::Models::Message)
          .to receive(:offset_page)
          .and_return([false, [[0, 0]], false])

        get "explorer/#{topic}/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Watermark offsets')
        expect(body).to include('high: 1')
        expect(body).to include('low: 0')
        expect(body).to include(removed_or_compacted)
        expect(body).not_to include(no_data)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are multiple pages' do
      before { produce_many(topic, Array.new(100, '1')) }

      context 'when we view the from the highest available offset' do
        before { get "explorer/#{topic}/0?offset=99" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/#{topic}/0/99")
          expect(body).not_to include("/explorer/#{topic}/0/98")
          expect(body).not_to include("/explorer/#{topic}/0/100")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we view the from the highest full page' do
        before { get "explorer/#{topic}/0?offset=75" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/#{topic}/0/99")
          expect(body).to include("/explorer/#{topic}/0/75")
          expect(body).not_to include("/explorer/#{topic}/0/100")
          expect(body).not_to include("/explorer/#{topic}/0/74")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
          # 26 because 25 for details + one for breadcrumbs
          expect(body.scan("href=\"/explorer/#{topic}/0/").count).to eq(26)
        end
      end

      context 'when we view the lowest offsets' do
        before { get "explorer/#{topic}/0?offset=0" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/#{topic}/0/0")
          expect(body).to include("/explorer/#{topic}/0/24")
          expect(body).not_to include("/explorer/#{topic}/0/99")
          expect(body).not_to include("/explorer/#{topic}/0/75")
          expect(body).not_to include("/explorer/#{topic}/0/25")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
          # 26 because 25 for details + one for breadcrumbs
          expect(body.scan("href=\"/explorer/#{topic}/0/").count).to eq(26)
        end
      end

      context 'when we go way above the existing offsets' do
        before { get "explorer/#{topic}/0?offset=1000" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include('This page does not contain any data')
          expect(body).not_to include(pagination)
          expect(body).not_to include("/explorer/#{topic}/0/99")
          expect(body).not_to include("/explorer/#{topic}/0/100")
          expect(body).not_to include(support_message)
        end
      end
    end
  end

  describe '#show' do
    let(:cannot_deserialize) { 'We could not deserialize the data due' }

    context 'when requested offset does not exist' do
      before { get "explorer/#{topic}/0/0" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested partition does not exist' do
      before { get "explorer/#{topic}/1/0" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested message exists and can be deserialized' do
      before do
        produce(topic, { test: 'me' }.to_json)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).to include('Download raw')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists, can be deserialized and comes from a pattern' do
      before do
        topic_name = topic

        Karafka::App.routes.draw do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { '16d6d5c5-d8a8-45fc-ae1d-34e134772b98' })
          end
        end

        produce(topic, { test: 'me' }.to_json)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).to include('Download raw')
        expect(body).to include('16d6d5c5-d8a8-45fc-ae1d-34e134772b98')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists, can be deserialized and raw download is off' do
      before do
        allow(::Karafka::Web.config.ui.visibility.filter)
          .to receive(:download?)
          .and_return(false)

        produce(topic, { test: 'me' }.to_json)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).not_to include('Download raw')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists, can be deserialized but export is off' do
      before do
        allow(::Karafka::Web.config.ui.visibility.filter)
          .to receive(:export?)
          .and_return(false)

        produce(topic, { test: 'me' }.to_json)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('Download raw')
        expect(body).not_to include('Export as JSON')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists but is nil' do
      before do
        produce(topic, nil)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when message exists but cannot be deserialized' do
      before do
        produce(topic, '{1=')
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Metadata')
        expect(body).to include('<code class="wrapped json')
        expect(body).to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('Export as JSON')
      end
    end

    context 'when viewing a message but having a different one in the offset' do
      before { get "explorer/#{topic}/0/0?offset=1" }

      it 'expect to redirect to the one from the offset' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include("explorer/#{topic}/0/1")
      end
    end

    context 'when requested message exists and is of 1 byte' do
      before do
        produce(topic, rand(256).chr)
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('0.001 KB')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists and is of 100 byte' do
      before do
        produce(topic, SecureRandom.random_bytes(100))
        get "explorer/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="wrapped json')
        expect(body).to include('Metadata')
        expect(body).to include('0.0977 KB')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#recent' do
    let(:payload1) { SecureRandom.uuid }
    let(:payload2) { SecureRandom.uuid }

    context 'when getting recent for the whole topic' do
      let(:partitions) { 2 }

      context 'when recent is on the first partition' do
        before do
          produce(topic, payload1, partition: 1)
          produce(topic, payload2, partition: 0)
          get "explorer/#{topic}/recent"
        end

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include(payload2)
          expect(body).to include(topic)
          expect(body).not_to include(payload1)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
        end
      end

      context 'when recent is on another partition' do
        before do
          produce(topic, payload1, partition: 0)
          sleep(0.1)
          produce(topic, payload2, partition: 1)
          get "explorer/#{topic}/recent"
        end

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include(payload2)
          expect(body).to include(topic)
          expect(body).not_to include(payload1)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
        end
      end
    end

    context 'when getting recent for the partition' do
      before do
        produce(topic, payload1, partition: 0)
        get "explorer/#{topic}/0/recent"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(payload1)
        expect(body).to include(topic)
        expect(body).not_to include(payload2)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#surrounding' do
    context 'when given offset is lower than that exists' do
      before { get "explorer/#{topic}/0/0/surrounding" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when given offset is higher than that exists' do
      before { get "explorer/#{topic}/0/100/surrounding" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when given message is the only one' do
      before do
        produce(topic, { test: 'me' }.to_json)
        get "explorer/#{topic}/0/0/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when given message is the newest one' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/#{topic}/0/49/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=25")
      end
    end

    context 'when given message is first out of many' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/#{topic}/0/0/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when given message is a middle one out of many' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/#{topic}/0/25/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=12")
      end
    end
  end

  describe '#closest' do
    context 'when requested topic does not exist' do
      before { get 'explorer/topic/100/2023-10-10/12:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested date is not a valid date' do
      before { get 'explorer/topic/100/2023-13-10/27:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when we have only one older message' do
      before do
        produce(topic, '1')
        get "explorer/#{topic}/0/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/#{topic}/0/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time on a higher partition' do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, '1'), partition: 1)
        get "explorer/#{topic}/1/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/1?offset=0")
      end
    end

    context 'when we have many messages and we request later time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/#{topic}/0/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0?offset=99")
      end
    end

    context 'when we request a time on an empty topic partition' do
      before { get "explorer/#{topic}/0/2100-01-01/12:00:12" }

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/#{topic}/0")
      end
    end
  end
end
