# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:search_button) { 'title="Search in this topic"' }
  let(:partitions) { 1 }

  describe '#topic' do
    context 'when we view topic without any messages' do
      before { get "scheduled_messages/explorer/#{topic}" }

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

    context 'when we view topic with one tombstone message' do
      before do
        produce_many(topic, [nil])
        get "scheduled_messages/explorer/#{topic}"
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

    context 'when we view topic with one cancel message' do
      before do
        produce_many(topic, [nil], headers: { 'schedule_source_type' => 'cancel' })
        get "scheduled_messages/explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include('total: 1')
        expect(body).to include('cancel')
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
        get "scheduled_messages/explorer/#{topic}"
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
        produce_many(topic, Array.new(30, '1'), headers: { 'schedule_source_type' => 'schedule' })
        get "scheduled_messages/explorer/#{topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include('<span class="badge  badge-primary">schedule</span>')
        expect(body).to include(breadcrumbs)
        expect(body).to include(pagination)
        expect(body).to include("#{topic}/0/5")
        expect(body).not_to include(support_message)
      end
    end

    context 'when we view first page from a topic with one partition with transactional data' do
      before do
        produce_many(
          topic,
          Array.new(30, '1'),
          type: :transactional,
          headers: { 'schedule_source_type' => 'schedule' }
        )
        get "scheduled_messages/explorer/#{topic}"
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
  end

  describe '#partition' do
    let(:no_data) { 'This partition is empty and does not contain any data' }

    context 'when given partition does not exist' do
      before { get "scheduled_messages/explorer/#{topic}/1" }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when no data in the given partition' do
      before { get "scheduled_messages/explorer/#{topic}/0" }

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
        get "scheduled_messages/explorer/#{topic}/0"
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
        get "scheduled_messages/explorer/#{topic}/0"
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

        get "scheduled_messages/explorer/#{topic}/0"
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

    context 'when there are multiple pages' do
      before { produce_many(topic, Array.new(100, '1')) }

      context 'when we view the from the highest available offset' do
        before { get "scheduled_messages/explorer/#{topic}/0?offset=99" }

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
        before { get "scheduled_messages/explorer/#{topic}/0?offset=75" }

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
        before { get "scheduled_messages/explorer/#{topic}/0?offset=0" }

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
        before { get "scheduled_messages/explorer/#{topic}/0?offset=1000" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include('This page does not contain any data')
          expect(body).not_to include('Watermark offsets')
          expect(body).not_to include('high: 100')
          expect(body).not_to include('low: 0')
          expect(body).not_to include(pagination)
          expect(body).not_to include("/explorer/#{topic}/0/99")
          expect(body).not_to include("/explorer/#{topic}/0/100")
          expect(body).not_to include(support_message)
        end
      end
    end
  end

  describe '#closest' do
    context 'when requested topic does not exist' do
      before { get 'scheduled_messages/explorer/topic/100/2023-10-10/12:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when requested date is not a valid date' do
      before { get 'scheduled_messages/explorer/topic/100/2023-13-10/27:12:12' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when we have only one older message' do
      before do
        produce(topic, '1')
        get "scheduled_messages/explorer/#{topic}/0/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/scheduled_messages/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "scheduled_messages/explorer/#{topic}/0/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/scheduled_messages/explorer/#{topic}/0?offset=0")
      end
    end

    context 'when we have many messages and we request earlier time on a higher partition' do
      let(:partitions) { 2 }

      before do
        produce_many(topic, Array.new(100, '1'), partition: 1)
        get "scheduled_messages/explorer/#{topic}/1/2000-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/scheduled_messages/explorer/#{topic}/1?offset=0")
      end
    end

    context 'when we have many messages and we request later time' do
      before do
        produce_many(topic, Array.new(100, '1'))
        get "scheduled_messages/explorer/#{topic}/0/2100-01-01/12:00:12"
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/scheduled_messages/explorer/#{topic}/0?offset=99")
      end
    end

    context 'when we request a time on an empty topic partition' do
      before { get "scheduled_messages/explorer/#{topic}/0/2100-01-01/12:00:12" }

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq("/scheduled_messages/explorer/#{topic}/0")
      end
    end
  end
end
