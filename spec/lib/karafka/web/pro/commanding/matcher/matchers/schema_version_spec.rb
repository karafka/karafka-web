# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(schema_version_value) }

  let(:current_schema_version) { '1.2.0' }

  before do
    stub_const('Karafka::Web::Pro::Commanding::Dispatcher::SCHEMA_VERSION', current_schema_version)
  end

  describe '#matches?' do
    context 'when value matches current schema version' do
      let(:schema_version_value) { current_schema_version }

      it { expect(matcher.matches?).to be true }
    end

    context 'when value does not match current schema version' do
      let(:schema_version_value) { '2.0.0' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when value is an older schema version' do
      let(:schema_version_value) { '1.0.0' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when value is nil' do
      let(:schema_version_value) { nil }

      it { expect(matcher.matches?).to be false }
    end
  end
end
