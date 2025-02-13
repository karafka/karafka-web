# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  before { Karafka::Web.config.topics.consumers.commands = commands_topic }

  let(:commands_topic) { generate_topic_name }

  before { allow(Karafka::Web.producer).to receive(:produce_async) }

  describe '.request' do
    let(:process_id) { 'process123' }
    let(:command_name) { 'quiet' }

    it 'dispatches a request message with the correct structure' do
      described_class.request(command_name, process_id)

      expect(Karafka::Web.producer).to have_received(:produce_async).with(
        hash_including(
          topic: commands_topic,
          key: process_id,
          partition: 0
        )
      )
    end
  end

  describe '.result' do
    let(:process_id) { 'process123' }
    let(:command_name) { 'pause' }
    let(:result) { { success: true } }

    it 'dispatches a result message with the correct structure' do
      described_class.result(result, process_id, command_name)

      expect(Karafka::Web.producer).to have_received(:produce_async).with(
        hash_including(
          topic: commands_topic,
          key: process_id,
          partition: 0
        )
      )
    end
  end
end
