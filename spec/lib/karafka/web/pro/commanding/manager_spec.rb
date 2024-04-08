# frozen_string_literal: true

RSpec.describe_current do
  subject(:manager) { described_class.send(:new) }

  describe '#on_app_running' do
    before { allow(manager).to receive(:async_call) }

    it 'expect to start listening for commands asynchronously' do
      manager.on_app_running(nil)

      expect(manager).to have_received(:async_call).with('karafka.web.pro.commanding.manager')
    end
  end

  describe '#on_app_stopping' do
    let(:listener) { Karafka::Web::Pro::Commanding::Listener.new }

    before do
      allow(listener.class).to receive(:new).and_return(listener)
      allow(listener).to receive(:stop)
    end

    it 'expect to stop the listener' do
      manager.on_app_stopping(nil)
      expect(listener).to have_received(:stop)
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
