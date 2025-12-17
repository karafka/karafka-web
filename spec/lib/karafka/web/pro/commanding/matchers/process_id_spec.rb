# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(message) }

  let(:current_process_id) { 'process-123' }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { matchers: matchers }
    )
  end
  let(:matchers) { {} }

  before do
    allow(Karafka::Web.config.tracking.consumers.sampler)
      .to receive(:process_id)
      .and_return(current_process_id)
  end

  describe '#apply?' do
    context 'when process_id is not specified in matchers' do
      let(:matchers) { {} }

      it { expect(matcher.apply?).to be false }
    end

    context 'when process_id is specified in matchers' do
      let(:matchers) { { process_id: current_process_id } }

      it { expect(matcher.apply?).to be true }
    end
  end

  describe '#matches?' do
    context 'when process_id matches current process ID' do
      let(:matchers) { { process_id: current_process_id } }

      it { expect(matcher.matches?).to be true }
    end

    context 'when process_id does not match current process ID' do
      let(:matchers) { { process_id: 'other-process-456' } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when process_id is empty string' do
      let(:matchers) { { process_id: '' } }

      it { expect(matcher.matches?).to be false }
    end
  end
end
