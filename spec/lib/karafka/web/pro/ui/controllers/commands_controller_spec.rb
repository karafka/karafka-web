# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:commands_topic) { create_topic }
  let(:no_commands) { 'No commands found.' }

  describe '#index' do
    context 'when commands topic does not exist' do
      before do
        topics_config.consumers.commands = SecureRandom.uuid

        get 'commands'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when there are no commands' do
      before do
        topics_config.consumers.commands = commands_topic

        get 'commands'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include(no_commands)
      end
    end

    context 'when command is with a schema that does not match system one' do
      before do
        topics_config.consumers.commands = commands_topic
        data = Fixtures.consumers_commands_json
        data[:schema_version] = '0.0.1'
        produce(commands_topic, data.to_json)
        get 'commands'
      end

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_commands)
        expect(body).not_to include(pagination)
        expect(body).not_to include('<span class="badge badge-primary">')
        expect(body).not_to include('/consumers/shinra:1404842:f66b40c75f92/subscriptions')
        expect(body).not_to include('/commands/0')
        expect(body).to include(breadcrumbs)
        expect(body).to include('Incompatible command schema.')
      end
    end

    context 'when there are active commands' do
      before { get 'commands' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_commands)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('<span class="badge badge-primary">')
        expect(body).to include('command')
        expect(body).to include('quiet')
        expect(body).to include('/consumers/shinra:1404842:f66b40c75f92/subscriptions')
        expect(body).to include('/commands/0')
      end
    end

    context 'when there are more commands that we fit in a single page' do
      before do
        topics_config.consumers.commands = commands_topic

        34.times do
          %w[
            probe
            stop
            quiet
          ].each do |type|
            data = Fixtures.consumers_commands_json("v1.0.0_#{type}", symbolize_names: false)
            id = ['*', SecureRandom.uuid].sample
            data['process']['id'] = id
            produce(commands_topic, data.to_json, key: id)
          end
        end
      end

      context 'when we visit first page' do
        before { get 'commands' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('commands/99')
          expect(body).to include('<a href="/consumers/')
          expect(body).to include('probe')
          expect(body).to include('quiet')
          expect(body).to include('stop')
        end
      end

      context 'when we visit second page' do
        before { get 'commands/overview?offset=52' }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('commands/53')
          expect(body).not_to include('commands/99')
          expect(body).to include('<a href="/consumers/')
          expect(body).to include('probe')
          expect(body).to include('quiet')
          expect(body).to include('stop')
          expect(body).not_to include(support_message)
        end
      end

      context 'when we go beyond available offsets' do
        before { get 'commands/overview?offset=200' }

        it do
          expect(response).to be_ok
          expect(body).not_to include(pagination)
          expect(body).to include(no_commands)
          expect(body).not_to include(support_message)
        end
      end
    end
  end

  describe '#show' do
    let(:incompatible_message) { 'Incompatible Command Schema' }

    context 'when visiting offset that does not exist' do
      before { get 'commands/123456' }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    %w[
      probe
      quiet
      stop
      quiet_all
      stop_all
    ].each do |command|
      context "when visiting #{command} command" do
        before do
          topics_config.consumers.commands = commands_topic
          produce(commands_topic, Fixtures.consumers_commands_file("v1.0.0_#{command}.json"))
          get 'commands/0'
        end

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).to include('<td>Type</td>')
          expect(body).to include('<code class="json"')
          # quiet_all and stop_all display just stop with a wildcard target
          expect(body).to include("<td>#{command.split('_').first}</td>")
          expect(body).not_to include(incompatible_message)
        end
      end

      context "when visiting #{command} command that is not with a compatible schema" do
        before do
          topics_config.consumers.commands = commands_topic
          data = Fixtures.consumers_commands_json("v1.0.0_#{command}")
          data[:schema_version] = '0.0.1'
          produce(commands_topic, data.to_json)
          get 'commands/0'
        end

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).not_to include(pagination)
          expect(body).not_to include(support_message)
          expect(body).not_to include('<td>Type</td>')
          expect(body).not_to include('<code class="json"')
          expect(body).not_to include("<td>#{command}</td>")
          expect(body).to include(incompatible_message)
        end
      end
    end

    context 'when visiting probe result' do
      before do
        topics_config.consumers.commands = commands_topic
        produce(commands_topic, Fixtures.consumers_commands_file('v1.0.0_probe_result.json'))
        get 'commands/0'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).not_to include(incompatible_message)
        expect(body).to include('rb:539:in `rd_kafka_consumer_poll')
        expect(body).to include('Metadata')
        expect(body).to include('probe result')
        expect(body).to include('/consumers/shinra:397793:6fa3f39acf46')
      end
    end

    context 'when visiting probe result that is not with a compatible schema' do
      before do
        topics_config.consumers.commands = commands_topic
        data = Fixtures.consumers_commands_json('v1.0.0_probe_result')
        data[:schema_version] = '0.0.1'
        produce(commands_topic, data.to_json)
        get 'commands/0'
      end

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include(incompatible_message)
      end
    end
  end

  describe '#recent' do
    context 'when commands topic does not exist' do
      before do
        topics_config.consumers.commands = SecureRandom.uuid

        get 'commands/recent'
      end

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context 'when no messages are present' do
      before do
        topics_config.consumers.commands = commands_topic
        get 'commands/recent'
      end

      it do
        expect(response.status).to eq(302)
        expect(response.location).to eq('/commands')
      end
    end

    context 'when message exists' do
      before { get 'commands/recent' }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(pagination)
        expect(body).not_to include(support_message)
        expect(body).to include('<td>Type</td>')
        expect(body).to include('<code class="json"')
        expect(body).to include('<td>quiet</td>')
      end
    end
  end
end
