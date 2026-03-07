# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:event) { {} }
  let(:reporter) { Karafka::Web.config.tracking.consumers.reporter }

  before do
    reporter.stubs(:report)
    reporter.stubs(:report!)
  end

  describe "#on_connection_listener_before_fetch_loop" do
    it do
      listener.on_connection_listener_before_fetch_loop(event)
      reporter.expects(:report) # MOCHA_REORDER
    end
  end

  describe "#on_app_quieting" do
    it do
      listener.on_app_quieting(event)
      reporter.expects(:report!) # MOCHA_REORDER
    end
  end

  describe "#on_app_quiet" do
    it do
      listener.on_app_quiet(event)
      reporter.expects(:report!) # MOCHA_REORDER
    end
  end

  describe "#on_app_stopping" do
    it do
      listener.on_app_stopping(event)
      reporter.expects(:report!) # MOCHA_REORDER
    end
  end

  describe "#on_app_stopped" do
    it do
      listener.on_app_stopped(event)
      reporter.expects(:report!) # MOCHA_REORDER
    end
  end
end
