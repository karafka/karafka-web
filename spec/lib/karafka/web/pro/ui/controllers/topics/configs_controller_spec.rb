# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe '#index' do
    context 'when trying to read configs of a non-existing topic' do
      before { get "topics/#{generate_topic_name}/config" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when getting configs of an existing topic' do
      before { get "topics/#{topic}/config" }

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

  describe '#edit' do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }
    let(:property_name) { 'cleanup.policy' }

    context 'when topics management feature is enabled' do
      context 'when property exists and is editable' do
        before do
          test_topic
          get "topics/#{topic_name}/config/#{property_name}/edit"
        end

        it 'renders edit form with all required elements' do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include("Topic #{topic_name} - Edit #{property_name}")
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)

          # Form elements and structure
          expect(body).to include('method="post"')
          expect(body).to include('name="_method" value="put"')
          expect(body).to include('Update Property')
          expect(body).to include('Cancel')

          # Warnings and hints
          expect(body).to include('Configuration Update Warning')
          expect(body).to include('Changing topic configurations may affect topic behavior')
          expect(body).to include('Some changes may take time to propagate')
          expect(body).to include('Before updating this configuration:')
        end
      end

      context 'when property does not exist' do
        before do
          test_topic
          get "topics/#{topic_name}/config/non-existent-property/edit"
        end

        it 'returns not found status' do
          expect(status).to eq(404)
        end
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        get "topics/#{topic_name}/config/#{property_name}/edit"
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when topic does not exist' do
      before { get 'topics/non-existent-topic/config/cleanup.policy/edit' }

      it 'returns not found status' do
        expect(status).to eq(404)
      end
    end
  end

  describe '#update' do
    let(:topic_name) { generate_topic_name }
    let(:test_topic) { create_topic(topic_name: topic_name) }
    let(:property_name) { 'max.message.bytes' }
    let(:property_value) { rand(1_000..100_000) }
    let(:default_params) { { property_value: property_value } }
    let(:updated_value) do
      Karafka::Web::Ui::Models::Topic.find(topic_name).configs.find do |config|
        config.name == 'max.message.bytes'
      end.value
    end

    context 'when topics management feature is enabled' do
      context 'when update succeeds' do
        before do
          test_topic
          put "topics/#{topic_name}/config/#{property_name}", default_params
        end

        it 'updates config and redirects with success message' do
          expect(response.status).to eq(302)
          expect(response.location).to end_with("/topics/#{topic_name}/config")
          expect(flash[:success]).to include("Topic #{topic_name} property #{property_name}")
          expect(updated_value).to eq(property_value.to_s)
        end
      end

      context 'when update fails' do
        let(:error_message) { 'Invalid value' }
        let(:property_value) { '-1' }

        before do
          test_topic
          put "topics/#{topic_name}/config/#{property_name}", default_params
        end

        it 'renders edit form with error messages' do
          expect(response).to be_ok
          expect(body).to include('Configuration Update Warning')
          expect(body).to include(error_message)
          expect(body).to include(topic_name)
          expect(body).to include(property_name)
          expect(body).to include(property_value)
        end
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        put "topics/#{topic_name}/config/#{property_name}", default_params
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when topic does not exist' do
      before { put 'topics/non-existent-topic/config/cleanup.policy', default_params }

      it 'returns not found status' do
        expect(status).to eq(404)
      end
    end

    context 'when property does not exist' do
      before do
        test_topic
        put "topics/#{topic_name}/config/non-existent-property", default_params
      end

      it 'returns not found status' do
        expect(status).to eq(404)
      end
    end
  end
end
