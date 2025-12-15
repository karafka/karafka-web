# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new }

  let(:process_id) { '1234' }
  let(:schema_version) { '1.0' }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      key: message_key,
      payload: message_payload,
      headers: { 'type' => message_payload[:type] }
    )
  end

  before do
    allow(Karafka::Web.config.tracking.consumers.sampler)
      .to receive(:process_id)
      .and_return(process_id)

    stub_const('Karafka::Web::Pro::Commanding::Dispatcher::SCHEMA_VERSION', schema_version)
  end

  context 'when message is for all processes and is a command of current schema version' do
    let(:message_key) { '*' }
    let(:message_payload) { { type: 'request', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be true }
  end

  context 'when message is for this process and is a command of current schema version' do
    let(:message_key) { process_id }
    let(:message_payload) { { type: 'request', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be true }
  end

  context 'when message key does not match current process id or "*"' do
    let(:message_key) { 'other_process_id' }
    let(:message_payload) { { type: 'request', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be false }
  end

  context 'when message type is not command' do
    let(:message_key) { '*' }
    let(:message_payload) { { type: 'result', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be false }
  end

  context 'when message schema version does not match' do
    let(:message_key) { '*' }
    let(:message_payload) { { type: 'request', schema_version: '2.0' } }

    it { expect(matcher.matches?(message)).to be false }
  end

  context 'when command has consumer_group_id' do
    let(:message_key) { '*' }
    let(:consumer_group) { instance_double('ConsumerGroup', id: 'my_consumer_group') }

    before do
      allow(Karafka::App).to receive(:routes).and_return([consumer_group])
    end

    context 'when consumer_group_id matches a local consumer group' do
      let(:message_payload) do
        {
          type: 'request',
          schema_version: schema_version,
          command: { consumer_group_id: 'my_consumer_group' }
        }
      end

      it { expect(matcher.matches?(message)).to be true }
    end

    context 'when consumer_group_id does not match any local consumer group' do
      let(:message_payload) do
        {
          type: 'request',
          schema_version: schema_version,
          command: { consumer_group_id: 'other_consumer_group' }
        }
      end

      it { expect(matcher.matches?(message)).to be false }
    end

    context 'when command does not have consumer_group_id' do
      let(:message_payload) do
        {
          type: 'request',
          schema_version: schema_version,
          command: { name: 'probe' }
        }
      end

      it { expect(matcher.matches?(message)).to be true }
    end

    context 'when payload has no command key' do
      let(:message_payload) do
        {
          type: 'request',
          schema_version: schema_version
        }
      end

      it { expect(matcher.matches?(message)).to be true }
    end
  end
end
