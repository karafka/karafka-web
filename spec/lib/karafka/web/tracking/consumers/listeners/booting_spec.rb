# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:scheduler) { ::Karafka::Web.config.tracking.scheduler }

  let(:event) do
    Karafka::Core::Monitoring::Event.new(
      rand,
      type: 'test_type'
    )
  end

  describe '#on_app_running' do
    before { allow(scheduler).to receive(:async_call) }

    it 'expect to trigger async call' do
      listener.on_app_running(event)

      expect(scheduler).to have_received(:async_call)
    end
  end
end
