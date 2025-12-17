# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(message) }

  let(:current_schema_version) { '1.2.0' }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { schema_version: schema_version_value }
    )
  end

  before do
    stub_const('Karafka::Web::Pro::Commanding::Dispatcher::SCHEMA_VERSION', current_schema_version)
  end

  describe '#matches?' do
    context 'when message schema version matches current' do
      let(:schema_version_value) { current_schema_version }

      it { expect(matcher.matches?).to be true }
    end

    context 'when message schema version does not match current' do
      let(:schema_version_value) { '2.0.0' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when message schema version is older' do
      let(:schema_version_value) { '1.0.0' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when message schema version is nil' do
      let(:schema_version_value) { nil }

      it { expect(matcher.matches?).to be false }
    end
  end
end
