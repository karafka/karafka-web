# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(message) }

  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      headers: { 'type' => message_type }
    )
  end

  describe '#matches?' do
    context 'when message type is request' do
      let(:message_type) { 'request' }

      it { expect(matcher.matches?).to be true }
    end

    context 'when message type is result' do
      let(:message_type) { 'result' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when message type is acceptance' do
      let(:message_type) { 'acceptance' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when message type is nil' do
      let(:message_type) { nil }

      it { expect(matcher.matches?).to be false }
    end
  end
end
