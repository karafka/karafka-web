# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  before { Karafka::Web.config.topics.consumers.commands.name = commands_topic }

  let(:commands_topic) { generate_topic_name }

  before { allow(Karafka::Web.producer).to receive(:produce_async) }

  describe '.request' do
    let(:command_name) { 'quiet' }

    context 'without matchers' do
      it 'dispatches a request message without key (filtering via matchers)' do
        described_class.request(command_name)

        expect(Karafka::Web.producer).to have_received(:produce_async).with(
          hash_including(
            topic: commands_topic,
            partition: 0
          )
        )
      end
    end

    context 'with process_id in matchers' do
      let(:process_id) { 'process123' }

      it 'dispatches request with matchers for filtering' do
        described_class.request(command_name, {}, matchers: { process_id: process_id })

        expect(Karafka::Web.producer).to have_received(:produce_async).with(
          hash_including(
            topic: commands_topic,
            partition: 0
          )
        )
      end
    end
  end

  describe '.result' do
    let(:process_id) { 'process123' }
    let(:command_name) { 'pause' }
    let(:result) { { success: true } }

    it 'dispatches a result message with the correct structure' do
      described_class.result(command_name, process_id, result)

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
