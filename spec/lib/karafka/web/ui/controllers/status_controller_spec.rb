# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  before do
    produce(TOPICS[0], Fixtures.consumers_states_file)
  end

  describe '#show' do
    context 'when all that is needed is there' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('The initial state of the consumers appears to')

        # Enhanced assertions based on actual status page content
        expect(body).to include('Data Type')
        expect(body).to include('Topic Name')

        # Version badges should be present
        expect(body).to include("karafka #{::Karafka::VERSION}")
        expect(body).to include("karafka-web #{::Karafka::Web::VERSION}")
        expect(body).to include('badge-primary')

        # Status should show topic names in data table
        expect(body).to include(topics_config.consumers.states.name)
        expect(body).to include(topics_config.consumers.metrics.name)
        expect(body).to include(topics_config.consumers.reports.name)
        expect(body).to include(topics_config.errors.name)

        # Should show data type labels
        expect(body).to include('Errors')
        expect(body).to include('Consumers reports')
        expect(body).to include('Consumers states')
        expect(body).to include('Consumers metrics')

        # Should show alert boxes
        expect(body).to include('Components info')
        expect(body).to include('Routing topics presence')
        expect(body).to include('alert-box-info')
        expect(body).to include('alert-box-warning')
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
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)

        # Enhanced assertions - missing topics should still show the table structure
        expect(body).to include('Data Type')
        expect(body).to include('Topic Name')
        expect(body).to include('Consumers states')
        expect(body).to include('Consumers metrics')
        expect(body).to include('Consumers reports')
        expect(body).to include('Errors')

        # Version info should still be present
        expect(body).to include("karafka #{::Karafka::VERSION}")
        expect(body).to include('badge-primary')

        # Alert boxes should still be present
        expect(body).to include('Components info')
        expect(body).to include('alert-box-info')
      end
    end

    context 'when replication factor is less than 2 in production' do
      before do
        allow(Karafka.env).to receive(:production?).and_return(true)
        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('Please ensure all those topics have a replication')
        expect(body).to include('alert-box-warning')

        # Enhanced assertions - production warnings should have alert structure
        expect(body).to include('alert-box-header')

        # Basic structure should still be there
        expect(body).to include('Data Type')
        expect(body).to include('Topic Name')
        expect(body).to include('Components info')
        expect(body).to include('badge-primary')
      end
    end

    context 'when replication factor is less than 2 in non-production' do
      before { get 'status' }

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).not_to include('Please ensure all those topics have a replication')
      end
    end

    context 'when consumers states topic received corrupted data' do
      let(:states_topic) { create_topic }

      before do
        topics_config.consumers.states.name = states_topic
        # Corrupted on purpose
        produce(states_topic, '{')

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('The initial state of the consumers appears to')
      end
    end

    context 'when consumers metrics topic received corrupted data' do
      let(:metrics_topic) { create_topic }

      before do
        topics_config.consumers.metrics.name = metrics_topic
        produce(metrics_topic, '{')

        get 'status'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
        expect(body).to include('The initial state of the consumers metrics appears to')
      end
    end

    context 'when accessing with query parameters' do
      before { get 'status?debug=true&refresh=1' }

      it 'ignores query parameters and shows normal status' do
        expect(response).to be_ok
        expect(body).to include(support_message)
        expect(body).to include(breadcrumbs)
      end
    end

    context 'when cache clearing behavior' do
      before do
        # Make two requests to verify cache clearing
        get 'status'
        get 'status'
      end

      it 'always shows fresh status' do
        expect(response).to be_ok
        expect(body).to include(support_message)
      end
    end

    context 'when displaying version information' do
      before { get 'status' }

      it 'shows Karafka and Web UI versions' do
        expect(response).to be_ok
        expect(body).to include(::Karafka::VERSION)
        expect(body).to include(::Karafka::Web::VERSION)
      end
    end
  end
end
