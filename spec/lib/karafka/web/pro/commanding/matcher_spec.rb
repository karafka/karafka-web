# frozen_string_literal: true

RSpec.describe_current do
  subject(:matcher) { described_class.new }

  let(:process_id) { '1234' }
  let(:schema_version) { '1.0' }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      key: message_key,
      payload: message_payload
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
    let(:message_payload) { { type: 'command', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be true }
  end

  context 'when message is for this process and is a command of current schema version' do
    let(:message_key) { process_id }
    let(:message_payload) { { type: 'command', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be true }
  end

  context 'when message key does not match current process id or "*"' do
    let(:message_key) { 'other_process_id' }
    let(:message_payload) { { type: 'command', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be false }
  end

  context 'when message type is not command' do
    let(:message_key) { '*' }
    let(:message_payload) { { type: 'result', schema_version: schema_version } }

    it { expect(matcher.matches?(message)).to be false }
  end

  context 'when message schema version does not match' do
    let(:message_key) { '*' }
    let(:message_payload) { { type: 'command', schema_version: '2.0' } }

    it { expect(matcher.matches?(message)).to be false }
  end
end
