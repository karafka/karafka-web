# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
