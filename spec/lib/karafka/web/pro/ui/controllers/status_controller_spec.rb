# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when topics are missing' do
      before do
        topics_config.consumers.states.name = generate_topic_name
        topics_config.consumers.metrics.name = generate_topic_name
        topics_config.consumers.reports.name = generate_topic_name
        topics_config.errors.name = generate_topic_name

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when topics exist with data' do
      let(:states_topic) { create_topic }
      let(:metrics_topic) { create_topic }
      let(:reports_topic) { create_topic }
      let(:errors_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        topics_config.consumers.metrics.name = metrics_topic
        topics_config.consumers.reports.name = reports_topic
        topics_config.errors.name = errors_topic

        ::Karafka::Web::Management::Actions::CreateInitialStates.new.call
        produce(metrics_topic, Fixtures.consumers_metrics_file)
        ::Karafka::Web::Management::Actions::MigrateStatesData.new.call

        get 'status'
      end

      it 'displays successful status with topic information' do
        expect(response).to be_ok
        expect(body).to include('Status')
        expect(body).not_to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include(states_topic)
        expect(body).to include(metrics_topic)
        expect(body).to include(reports_topic)
        expect(body).to include(errors_topic)
      end

      it 'shows connection details' do
        expect(body).to include('Components info')
        expect(body).to include('rdkafka')
        expect(body).to include('karafka')
      end

      it 'shows version information' do
        expect(body).to include(::Karafka::VERSION)
        expect(body).to include(::Karafka::Web::VERSION)
      end
    end
  end
end
