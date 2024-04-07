# frozen_string_literal: true

RSpec.describe Karafka::Web::Pro::Commanding::Manager do
  subject(:manager) { described_class.instance }

  before { allow(manager).to receive(:async_call) }

  describe '#on_app_running' do
    it 'expect to start listening for commands asynchronously' do
      manager.on_app_running(nil)

      expect(manager).to have_received(:async_call).with('karafka.web.pro.commanding.manager')
    end
  end

  describe '#on_app_stopping' do
    it 'expect to set stop flag to true' do
      manager.on_app_stopping(nil)

      expect(manager.instance_variable_get(:@stop)).to be true
    end
  end

  describe '#on_app_stopped' do
    before do
      manager.instance_variable_set(:@thread, Thread.new {})
      manager.instance_variable_get(:@thread).join(0.1) # Simulate thread finishing quickly
    end

    it 'expect to wait for the thread to finish' do
      manager.on_app_stopped(nil)
      # Test passes if no deadlocks occur and method executes correctly
    end
  end
end
