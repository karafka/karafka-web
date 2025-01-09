# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:commands_topic) { create_topic }
  let(:process_id) { SecureRandom.uuid }

  before { topics_config.consumers.commands = commands_topic }

  describe '#trace' do
    before { post "consumers/commanding/#{process_id}/trace" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.0.0')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'trace')
      expect(message.payload[:process]).to eq(id: process_id)
    end
  end

  describe '#quiet' do
    before { post "consumers/commanding/#{process_id}/quiet" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.0.0')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'quiet')
      expect(message.payload[:process]).to eq(id: process_id)
    end
  end

  describe '#stop' do
    before { post "consumers/commanding/#{process_id}/stop" }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command in the given topic with process_id reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq(process_id)
      expect(message.payload[:schema_version]).to eq('1.0.0')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'stop')
      expect(message.payload[:process]).to eq(id: process_id)
    end
  end

  describe '#quiet_all' do
    before { post 'consumers/commanding/quiet_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command in the given topic with wildcard process reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq('*')
      expect(message.payload[:schema_version]).to eq('1.0.0')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'quiet')
      expect(message.payload[:process]).to eq(id: '*')
    end
  end

  describe '#stop_all' do
    before { post 'consumers/commanding/stop_all' }

    it do
      expect(response.status).to eq(302)
      # Taken from referer and referer is nil in specs
      expect(response.location).to be_nil
    end

    it 'expect to create new command in the given topic with wildcard process reference' do
      # Dispatch of commands is async, so we have to wait
      sleep(1)
      message = Karafka::Admin.read_topic(commands_topic, 0, 1, -1).first
      expect(message.key).to eq('*')
      expect(message.payload[:schema_version]).to eq('1.0.0')
      expect(message.payload[:type]).to eq('command')
      expect(message.payload[:dispatched_at]).not_to be_nil
      expect(message.payload[:command]).to eq(name: 'stop')
      expect(message.payload[:process]).to eq(id: '*')
    end
  end
end
