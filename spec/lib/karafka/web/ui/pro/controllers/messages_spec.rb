# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::Pro::App }

  let(:topic) { create_topic }

  describe '#republish' do
    context 'when we want to republish message from a non-existing topic' do
      before { post 'messages/non-existing/0/1/republish' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when message exists' do
      let(:republished) { Karafka::Web::Ui::Models::Message.find(topic, 0, 1) }
      let(:payload) { rand.to_s }

      before do
        produce(topic, payload)
        post "messages/#{topic}/0/0/republish"
      end

      it do
        expect(response.status).to eq(302)
        # Taken fro referer and referer is nil in specs
        expect(response.location).to eq(nil)
        expect(republished.raw_payload).to eq(payload)
      end
    end
  end

  describe '#download' do
    context 'when we want to download message from a non-existing topic' do
      before { get 'messages/non-existing/0/1/download' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when message exists' do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.msg" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "messages/#{topic}/0/0/download"
      end

      it do
        expect(response).to be_ok
        expect(response.headers['content-disposition']).to eq(expected_disposition)
        expect(response.headers['content-type']).to eq('application/octet-stream')
        expect(response.body).to eq(payload)
      end
    end

    context 'when message exists but downloads are off' do
      let(:payload) { rand.to_s }

      before do
        allow(::Karafka::Web.config.ui.visibility.filter)
          .to receive(:download?)
          .and_return(false)

        produce(topic, payload)
        get "messages/#{topic}/0/0/download"
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#export' do
    context 'when we want to export message from a non-existing topic' do
      before { get 'messages/non-existing/0/1/export' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when message exists' do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        produce(topic, payload)
        get "messages/#{topic}/0/0/export"
      end

      it do
        expect(response).to be_ok
        expect(response.headers['content-disposition']).to eq(expected_disposition)
        expect(response.headers['content-type']).to eq('application/octet-stream')
        expect(response.body).to eq(payload)
      end
    end

    context 'when message exists on a dynamic topic with custom deserializer' do
      let(:payload) { rand.to_s }
      let(:expected_file_name) { "#{topic}_0_0_payload.json" }
      let(:expected_disposition) { "attachment; filename=\"#{expected_file_name}\"" }

      before do
        topic_name = topic

        Karafka::App.routes.draw do
          pattern(/#{topic_name}/) do
            active(false)
            deserializer(->(_message) { '1' })
          end
        end

        produce(topic, payload)
        get "messages/#{topic}/0/0/export"
      end

      it 'expect to use custom deserializer' do
        expect(response).to be_ok
        expect(response.headers['content-disposition']).to eq(expected_disposition)
        expect(response.headers['content-type']).to eq('application/octet-stream')
        expect(response.body).to eq('"1"')
      end
    end

    context 'when message exists but exports are off' do
      let(:payload) { rand.to_s }

      before do
        allow(::Karafka::Web.config.ui.visibility.filter)
          .to receive(:export?)
          .and_return(false)

        produce(topic, payload)
        get "messages/#{topic}/0/0/export"
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(403)
      end
    end
  end
end
