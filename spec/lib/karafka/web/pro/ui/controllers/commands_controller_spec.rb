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

    context 'when there are active commands' do
      before { get 'commands' }

      it do
        expect(response).to be_ok
        expect(body).not_to include(support_message)
        expect(body).not_to include(no_commands)
        expect(body).not_to include(pagination)
        expect(body).to include(breadcrumbs)
        expect(body).to include('<span class="badge bg-primary badge-topic">')
        expect(body).to include('command')
        expect(body).to include('quiet')
        expect(body).to include('/consumers/shinra:1404842:f66b40c75f92/subscriptions')
        expect(body).to include('/commands/0')
      end
    end

    context 'when there are more commands that we fit in a single page' do
      before do
        topics_config.consumers.commands = commands_topic

        34.times do |i|
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
    pending
  end

  describe '#recent' do
    pending
  end
end
