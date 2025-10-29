# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:event) { {} }
  let(:reporter) { Karafka::Web.config.tracking.consumers.reporter }

  before do
    allow(reporter).to receive(:report)
    allow(reporter).to receive(:report!)
  end

  describe '#on_connection_listener_before_fetch_loop' do
    it do
      listener.on_connection_listener_before_fetch_loop(event)
      expect(reporter).to have_received(:report)
    end
  end

  describe '#on_app_quieting' do
    it do
      listener.on_app_quieting(event)
      expect(reporter).to have_received(:report!)
    end
  end

  describe '#on_app_quiet' do
    it do
      listener.on_app_quiet(event)
      expect(reporter).to have_received(:report!)
    end
  end

  describe '#on_app_stopping' do
    it do
      listener.on_app_stopping(event)
      expect(reporter).to have_received(:report!)
    end
  end

  describe '#on_app_stopped' do
    it do
      listener.on_app_stopped(event)
      expect(reporter).to have_received(:report!)
    end
  end
end
