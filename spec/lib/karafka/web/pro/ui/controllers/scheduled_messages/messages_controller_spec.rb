# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic }

  describe '#cancel' do
    context 'when we want to cancel scheduled message from a non-existing topic' do
      before { post 'scheduled_messages/messages/non-existing/0/1/republish' }

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(404)
      end
    end

    context 'when message exists' do
      let(:cancelled) { Karafka::Web::Ui::Models::Message.find(topic, 0, 1) }
      let(:payload) { rand.to_s }

      before do
        produce(topic, payload)
        post "scheduled_messages/messages/#{topic}/0/0/cancel"
      end

      it do
        expect(response.status).to eq(302)
        # Taken from referer and referer is nil in specs
        expect(response.location).to eq(nil)
        expect(cancelled.raw_headers['schedule_source_type']).to eq('cancel')
      end
    end
  end
end
