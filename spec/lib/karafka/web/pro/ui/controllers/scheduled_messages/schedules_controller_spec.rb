# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe 'scheduled_messages/ path redirect' do
    context 'when visiting the scheduled_messages/ path without type indicator' do
      before { get 'scheduled_messages' }

      it 'expect to redirect to running schedules page' do
        expect(response.status).to eq(302)
        expect(response.headers['location']).to include('scheduled_messages/schedules')
      end
    end
  end

  describe '#index' do
    let(:no_groups) { 'We are unable to display data related to scheduled messages' }

    context 'when there are no schedules in routes nor any topics' do
      before { get 'scheduled_messages/schedules' }

      it do
        expect(response).to be_ok
        expect(body).to include(no_groups)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are schedules in routes but not created' do
      before do
        draw_routes do
          scheduled_messages('not_existing')
        end

        get 'scheduled_messages/schedules'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(no_groups)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there is one schedule and routes exist' do
      let(:messages_topic) { create_topic }
      let(:states_topic) { create_topic(topic_name: "#{messages_topic}_states") }

      before do
        states_topic
        messages_topic_ref = messages_topic

        draw_routes do
          scheduled_messages(messages_topic_ref)
        end

        get 'scheduled_messages/schedules'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(messages_topic)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(no_groups)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are many schedules and routes exist' do
      let(:messages_topic1) { create_topic }
      let(:states_topic1) { create_topic(topic_name: "#{messages_topic1}_states") }
      let(:messages_topic2) { create_topic }
      let(:states_topic2) { create_topic(topic_name: "#{messages_topic2}_states") }

      before do
        states_topic1
        messages_topic_ref1 = messages_topic1
        states_topic2
        messages_topic_ref2 = messages_topic2

        draw_routes do
          scheduled_messages(messages_topic_ref1)
          scheduled_messages(messages_topic_ref2)
        end

        get 'scheduled_messages/schedules'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(messages_topic1)
        expect(body).to include(messages_topic2)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(no_groups)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end
  end

  describe '#show' do
    let(:messages_topic) { create_topic }
    let(:states_topic) { create_topic(topic_name: "#{messages_topic}_states") }
    let(:no_states) { 'No state information for this partition is available.' }

    before do
      states_topic
      messages_topic_ref = messages_topic

      draw_routes do
        scheduled_messages(messages_topic_ref)
      end
    end

    context 'when there are no states for any of the partitions' do
      before { get "scheduled_messages/schedules/#{messages_topic}" }

      it do
        expect(response).to be_ok
        expect(body).to include(messages_topic)
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_states)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when there are state reports for partitions' do
      before do
        state = Fixtures.scheduled_messages_states_msg('current')
        produce(states_topic, state)

        get "scheduled_messages/schedules/#{messages_topic}"
      end

      it do
        expect(response).to be_ok
        expect(body).to include(messages_topic)
        expect(body).to include(breadcrumbs)
        expect(body).to include('2024-09-02')
        expect(body).not_to include(no_states)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end
  end
end
