# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:commands_topic) { create_topic }
  let(:process_id) { SecureRandom.uuid }

  before { topics_config.consumers.commands.name = commands_topic }

  describe '#trace' do
    before { post "consumers/commanding/#{process_id}/trace" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include('The Trace command has been dispatched to the')
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.2.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'consumers.trace')
      expect(message.payload[:matchers]).to eq({})
    end
  end

  describe '#quiet' do
    before { post "consumers/commanding/#{process_id}/quiet" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include('The Quiet command has been dispatched to the')
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.2.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'consumers.quiet')
      expect(message.payload[:matchers]).to eq({})
    end
  end

  describe '#stop' do
    before { post "consumers/commanding/#{process_id}/stop" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include('The Stop command has been dispatched to the')
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.2.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'consumers.stop')
      expect(message.payload[:matchers]).to eq({})
    end
  end

  describe '#quiet_all' do
    before { post 'consumers/commanding/quiet_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include('The Quiet command has been dispatched to all')
    end

    it 'expect to create new command in the given topic with wildcard process reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq('*')
      expect(message.payload[:schema_version]).to eq('1.2.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'consumers.quiet')
      expect(message.payload[:matchers]).to eq({})
    end
  end

  describe '#stop_all' do
    before { post 'consumers/commanding/stop_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to eq('/')
      expect(flash[:success]).to include('The Stop command has been dispatched to all')
    end

    it 'expect to create new command in the given topic with wildcard process reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq('*')
      expect(message.payload[:schema_version]).to eq('1.2.0')
      expect(message.payload[:type]).to eq('request')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'consumers.stop')
      expect(message.payload[:matchers]).to eq({})
    end
  end
end
