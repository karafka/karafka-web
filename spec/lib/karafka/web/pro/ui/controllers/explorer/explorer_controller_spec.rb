# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:removed_or_compacted) { 'This offset does not contain any data.' }
  let(:internal_topic) { "__#{generate_topic_name}" }
  let(:search_button) { 'title="Search in this topic"' }

  describe '#index' do
    before do
      create_topic(topic_name: internal_topic)
      get 'explorer/topics'
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).to include(topics_config.consumers.states.name)
      expect(body).to include(topics_config.consumers.metrics.name)
      expect(body).to include(topics_config.consumers.reports.name)
      expect(body).to include(topics_config.errors.name)
      expect(body).not_to include(internal_topic)
    end

    context 'when there are no topics' do
      before do
        allow(::Karafka::Web::Ui::Models::ClusterInfo).to receive(:topics).and_return([])
        get 'explorer/topics'
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

        get 'explorer/topics'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(topics_config.consumers.states.name)
        expect(body).to include(topics_config.consumers.metrics.name)
        expect(body).to include(topics_config.consumers.reports.name)
        expect(body).to include(topics_config.errors.name)
        expect(body).to include(internal_topic)
      end
    end
  end

  describe '#topic' do
    context 'when we view topic without any messages' do
      before { get "explorer/topics/#{topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include('This topic is empty and does not contain any data')
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('total: 1')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include(search_button)
      end
    end

    context 'when we view topic with one nil message' do
      before do
        produce_many(topic, [nil])
        get "explorer/topics/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include('total: 1')
        expect(body).to include(breadcrumbs)
        expect(body).to include(search_button)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view topic with one message with broken key' do
      let(:key_deserializer) { ->(_headers) { raise } }

      before do
        topic_name = topic
        deserializer = key_deserializer

        draw_routes do
          topic topic_name do
            active(false)
            # This will crash key deserialization, since it requires json
            deserializers(key: deserializer)
          end
        end

        produce_many(topic, [nil], key: '{')
        get "explorer/topics/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include('total: 1')
        expect(body).to include(breadcrumbs)
        expect(body).to include('[Deserialization Failed]')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/topics/#{topic}"
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
        get "explorer/topics/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/6")
        expect(body).to include("#{topic}/0/29")
        expect(body).to include(compacted_or_transactional_offset)
        expect(body).to include(search_button)
        expect(body).not_to include("#{topic}/0/30")
        expect(body).not_to include("#{topic}/0/4")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view last page from a topic with one partition with data' do
      before do
        produce_many(topic, Array.new(30, '1'))
        get "explorer/topics/#{topic}?page=2"
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
        get "explorer/topics/#{topic}"
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
        get "explorer/topics/#{topic}?page=6"
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
        get "explorer/topics/#{topic}?page=100"
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
      before { get "explorer/topics/#{topic}/1" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when given partition is more than 32bit C int' do
      before { get "explorer/topics/#{topic}/2147483648" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when no data in the given partition' do
      before { get "explorer/topics/#{topic}/0" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_data)
        expect(body).not_to include('high: 0')
        expect(body).not_to include('low: 0')
        expect(body).not_to include('Watermark offsets')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include(search_button)
      end
    end

    context 'when single result in a given partition is present' do
      before do
        produce(topic, '1')
        get "explorer/topics/#{topic}/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Watermark offsets')
        expect(body).to include('high: 1')
        expect(body).to include('low: 0')
        expect(body).to include(search_button)
        expect(body).not_to include(no_data)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when only single transactional result in a given partition is present' do
      before do
        produce(topic, '1', type: :transactional)
        get "explorer/topics/#{topic}/0"
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

        get "explorer/topics/#{topic}/0"
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
        before { get "explorer/topics/#{topic}/0?offset=99" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/topics/#{topic}/0/99")
          expect(body).not_to include("/explorer/topics/#{topic}/0/98")
          expect(body).not_to include("/explorer/topics/#{topic}/0/100")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
        end
      end

      context 'when we view the from the highest full page' do
        before { get "explorer/topics/#{topic}/0?offset=75" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/topics/#{topic}/0/99")
          expect(body).to include("/explorer/topics/#{topic}/0/75")
          expect(body).not_to include("/explorer/topics/#{topic}/0/100")
          expect(body).not_to include("/explorer/topics/#{topic}/0/74")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
          # 26 because 25 for details + one for breadcrumbs
          expect(body.scan("href=\"/explorer/topics/#{topic}/0/").count).to eq(26)
        end
      end

      context 'when we view the lowest offsets' do
        before { get "explorer/topics/#{topic}/0?offset=0" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('Watermark offsets')
          expect(body).to include('high: 100')
          expect(body).to include('low: 0')
          expect(body).to include(pagination)
          expect(body).to include("/explorer/topics/#{topic}/0/0")
          expect(body).to include("/explorer/topics/#{topic}/0/24")
          expect(body).not_to include("/explorer/topics/#{topic}/0/99")
          expect(body).not_to include("/explorer/topics/#{topic}/0/75")
          expect(body).not_to include("/explorer/topics/#{topic}/0/25")
          expect(body).not_to include(no_data)
          expect(body).not_to include(support_message)
          # 26 because 25 for details + one for breadcrumbs
          expect(body.scan("href=\"/explorer/topics/#{topic}/0/").count).to eq(26)
        end
      end

      context 'when we go way above the existing offsets' do
        before { get "explorer/topics/#{topic}/0?offset=1000" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('This page does not contain any data')
          expect(body).not_to include('Watermark offsets')
          expect(body).not_to include('high: 100')
          expect(body).not_to include('low: 0')
          expect(body).not_to include(pagination)
          expect(body).not_to include("/explorer/topics/#{topic}/0/99")
          expect(body).not_to include("/explorer/topics/#{topic}/0/100")
          expect(body).not_to include(support_message)
        end
      end
    end
  end

  describe '#show' do
    let(:cannot_deserialize) { 'We could not deserialize the <strong>payload</strong> due' }

    context 'when requested offset does not exist' do
      before { get "explorer/topics/#{topic}/0/0" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested partition does not exist' do
      before { get "explorer/topics/#{topic}/1/0" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested message exists and can be deserialized' do
      before do
        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).to include('Download raw')
        expect(body).to include('Republish')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists and has array headers' do
      before do
        produce(
          topic,
          { test: 'me' }.to_json,
          headers: {
            'super1' => 'tadam1',
            'super2' => 'tadam2'
          }
        )
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).to include('Download raw')
        expect(body).to include('Republish')
        expect(body).to include('super1')
        expect(body).to include('super2')
        expect(body).to include('tadam1')
        expect(body).to include('tadam2')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists but should not be republishable' do
      before do
        allow(::Karafka::Web.config.ui.policies.messages)
          .to receive(:republish?)
          .and_return(false)

        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).to include('Export as JSON')
        expect(body).to include('Download raw')
        expect(body).not_to include('Republish')
        expect(body).not_to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists, can be deserialized and comes from a pattern' do
      before do
        topic_name = topic
        draw_routes do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { '16d6d5c5-d8a8-45fc-ae1d-34e134772b98' })
          end
        end

        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
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
        allow(::Karafka::Web.config.ui.policies.messages)
          .to receive(:download?)
          .and_return(false)

        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
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
        allow(::Karafka::Web.config.ui.policies.messages)
          .to receive(:export?)
          .and_return(false)

        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
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
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists but is a system entry' do
      before do
        produce(topic, nil, type: :transactional)
        get "explorer/topics/#{topic}/0/1"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('The message has been removed through')
        expect(body).to include(pagination)
        expect(body).not_to include('<code class="json')
        expect(body).not_to include('Metadata')
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists but is too big to be presented' do
      before do
        topic_name = topic
        draw_routes do
          topic topic_name do
            active(false)
            deserializers(payload: ::Karafka::Web::Deserializer.new)
          end
        end

        data = Fixtures.consumers_metrics_json('current')
        # More than 512KB limit but less than 1MB default Kafka topic limit
        data[:too_much] = 'a' * 1024 * 800

        produce(
          topic,
          data.to_json,
          headers: { 'zlib' => '1' }
        )
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).to include('Message payloads larger than')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when trace_object_allocations_start is not available' do
      before do
        allow(ObjectSpace)
          .to receive(:respond_to?)
          .with(:trace_object_allocations_start)
          .and_return(false)

        produce(topic, '1')
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('Not Available')
      end
    end

    context 'when message exists but cannot be deserialized' do
      before do
        produce(topic, '{1=')
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Metadata')
        expect(body).to include('<code class="json')
        expect(body).to include(cannot_deserialize)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include('Export as JSON')
      end
    end

    context 'when key exists but cannot be deserialized' do
      let(:cannot_deserialize) { 'We could not deserialize the <strong>key</strong> due' }

      before do
        topic_name = topic
        draw_routes do
          topic topic_name do
            active(false)
            # This will crash key deserialization, since it requires json
            deserializers(key: ::Karafka::Web::Deserializer.new)
          end
        end

        produce(topic, '{}', key: '{')
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Metadata')
        expect(body).to include('<code class="json')
        expect(body).to include('')
        expect(body).to include('Export as JSON')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when viewing a message but having a different one in the offset' do
      before { get "explorer/topics/#{topic}/0/0?offset=1" }

      it 'expect to redirect to the one from the offset' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include("explorer/topics/#{topic}/0/1")
      end
    end

    context 'when requested message exists and is of 1 byte' do
      before do
        produce(topic, rand(256).chr)
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
        expect(body).to include('Metadata')
        expect(body).to include('0.001 KB')
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when requested message exists and is of 100 byte' do
      before do
        produce(topic, SecureRandom.random_bytes(100))
        get "explorer/topics/#{topic}/0/0"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('<code class="json')
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
          get "explorer/topics/#{topic}/recent"
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
          get "explorer/topics/#{topic}/recent"
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
        get "explorer/topics/#{topic}/0/recent"
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
      before { get "explorer/topics/#{topic}/0/0/surrounding" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when given offset is higher than that exists' do
      before { get "explorer/topics/#{topic}/0/100/surrounding" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when given message is the only one' do
      before do
        produce(topic, { test: 'me' }.to_json)
        get "explorer/topics/#{topic}/0/0/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when given message is the newest one' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/topics/#{topic}/0/49/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=25")
      end
    end

    context 'when given message is first out of many' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/topics/#{topic}/0/0/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when given message is a middle one out of many' do
      before do
        produce_many(topic, Array.new(50, '1'))
        get "explorer/topics/#{topic}/0/25/surrounding"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=12")
      end
    end
  end

  describe '#closest' do
    let(:now_in_ms) { (Time.now.to_f * 1_000).round }

    context 'when requested topic does not exist with date' do
      before { get 'explorer/topics/topic/100/closest/2023-10-10/12:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested topic does not exist with timestamp' do
      before { get 'explorer/topics/topic/100/closest/0' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested date is not a valid date' do
      before { get 'explorer/topics/topic/100/closest/2023-13-10/27:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested date is not a valid timestamp' do
      before { get 'explorer/topics/topic/100/closest/03142341231' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when we have only one older message with date' do
      before do
        produce(topic, '1')
        get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when we have a timestamp without seconds' do
      before do
        produce(topic, '1')
        get "explorer/topics/#{topic}/0/closest/2025-04-18/12:37"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when we have only one older message with timestamp' do
      before do
        produce(topic, '1')
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/topics/#{topic}/0/closest/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier timestamp' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms - 100_000}"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time on a higher partition' do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, '1'), partition: 1)
        get "explorer/topics/#{topic}/1/closest/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/1?offset=0")
      end
    end

    context 'when we have many messages and we request earlier timestamp on a higher partition' do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, '1'), partition: 1)
        get "explorer/topics/#{topic}/1/closest/#{now_in_ms - 100_000}"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/1?offset=0")
      end
    end

    context 'when we have many messages and we request later time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=99")
      end
    end

    context 'when we have many messages and we request later timestamp' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "explorer/topics/#{topic}/0/closest/#{now_in_ms + 100_000}"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0?offset=99")
      end
    end

    context 'when we request a time on an empty topic partition' do
      before { get "explorer/topics/#{topic}/0/closest/2100-01-01/12:00:12" }

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0")
      end
    end

    context 'when we request a timestamp on an empty topic partition' do
      before { get "explorer/topics/#{topic}/0/closest/#{now_in_ms}" }

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/explorer/topics/#{topic}/0")
      end
    end
  end
end
