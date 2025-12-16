# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(process_id_value) }

  let(:current_process_id) { 'process-123' }

  before do
    allow(Karafka::Web.config.tracking.consumers.sampler)
      .to receive(:process_id)
      .and_return(current_process_id)
  end

  describe '#matches?' do
    context 'when value is "*" (wildcard)' do
      let(:process_id_value) { '*' }

      it { expect(matcher.matches?).to be true }
    end

    context 'when value matches current process ID' do
      let(:process_id_value) { current_process_id }

      it { expect(matcher.matches?).to be true }
    end

    context 'when value does not match current process ID' do
      let(:process_id_value) { 'other-process-456' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when value is empty string' do
      let(:process_id_value) { '' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when value is nil' do
      let(:process_id_value) { nil }

      it { expect(matcher.matches?).to be false }
    end
  end
end
