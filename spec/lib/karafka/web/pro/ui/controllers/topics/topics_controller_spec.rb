# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:internal_topic) { "__#{generate_topic_name}" }

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

  describe '#new' do
    context 'when topics management feature is enabled' do
      before { get 'topics/new' }

      it 'renders successfully' do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).to include('Creating New Topic')
        expect(body).to include('Topic Name:')
        expect(body).to include('Number of Partitions:')
        expect(body).to include('Replication Factor:')
        expect(body).to include('Topic Creation Settings')
        expect(body).to include('Topic name cannot be changed after creation')
        expect(body).to include('Number of partitions can only be increased')
        expect(body).to include('value="5"') # Default partitions count
        expect(body).to include('value="1"') # Default replication factor
        expect(body).to include('pattern="[A-Za-z0-9\-_.]+"') # Topic name pattern
        expect(body).to include('maxlength="249"') # Topic name length limit
        expect(body).to include('min="1"') # Minimum partitions/replication
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false

        get 'topics/new'
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when form was previously submitted with errors' do
      before do
        get(
          'topics/new',
          topic_name: 'invalid-topic',
          partitions_count: '2',
          replication_factor: '1'
        )
      end

      it 'preserves the submitted values' do
        expect(body).to include('value="invalid-topic"')
        expect(body).to include('value="2"')
        expect(body).to include('value="1"')
      end
    end
  end

  describe '#create' do
    let(:topic_name) { generate_topic_name }
    let(:partitions_count) { 3 }
    let(:replication_factor) { 1 }
    let(:cluster_topics) { Karafka::Admin.cluster_info.topics.map { |t| t[:topic_name] } }
    let(:default_params) do
      {
        topic_name: topic_name,
        partitions_count: partitions_count,
        replication_factor: replication_factor
      }
    end

    context 'when topics management feature is enabled and data is correct' do
      before { post 'topics', default_params }

      it 'creates topic successfully' do
        expect(response.status).to eq(302)
        expect(response.location).to end_with('/topics')
        expect(flash[:success]).to include("Topic #{topic_name} successfully created")
        expect(cluster_topics).to include(topic_name)
      end
    end

    context 'when topics management feature is not enabled' do
      before do
        Karafka::Web.config.ui.topics.management.active = false
        post 'topics', default_params
      end

      it 'returns unauthorized status' do
        expect(response).not_to be_ok
        expect(status).to eq(403)
      end
    end

    context 'when topic creation fails because of rdkafka error' do
      let(:topic_name) { cluster_topics.first }
      let(:error_message) { 'Topic already exists' }

      before { post 'topics', default_params }

      it 'renders form with errors' do
        expect(response).to be_ok
        expect(body).to include('Creating New Topic')
        expect(body).to include('Please Correct the Following Errors Before Continuing')
        expect(body).to include(error_message)
        expect(body).to include("value=\"#{topic_name}\"")
        expect(body).to include("value=\"#{partitions_count}\"")
        expect(body).to include("value=\"#{replication_factor}\"")
      end
    end

    context 'with parameter validation' do
      shared_examples 'invalid parameter' do |params_override|
        before { post 'topics', default_params.merge(params_override) }

        it 'renders form' do
          expect(response).to be_ok
          expect(body).to include('Creating New Topic')
        end
      end

      it_behaves_like 'invalid parameter', topic_name: ''
      it_behaves_like 'invalid parameter', partitions_count: 0
      it_behaves_like 'invalid parameter', replication_factor: 0
    end

    context 'with topic name validation' do
      shared_examples 'topic name validation' do |topic_name, expected_success|
        before do
          allow(Karafka::Admin).to receive(:create_topic) if expected_success
          post 'topics', default_params.merge(topic_name: topic_name)
        end

        it "handles #{topic_name} as expected" do
          if expected_success
            expect(response.status).to eq(302)
            expect(response.location).to end_with('/topics')
          else
            expect(response).to be_ok
            expect(body).to include('Creating New Topic')
          end
        end
      end

      {
        'valid-topic' => true,
        'valid.topic' => true,
        'valid_topic' => true,
        'Valid123' => true,
        'invalid topic' => false,
        'invalid#topic' => false,
        'invalid@topic' => false,
        'a' * 250 => false
      }.each do |name, expected_success|
        it_behaves_like 'topic name validation', name, expected_success
      end
    end
  end

  describe '#edit' do
    pending 'tba'
  end

  describe '#delete' do
    pending 'tba'
  end
end
