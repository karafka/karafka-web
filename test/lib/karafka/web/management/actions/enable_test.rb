# frozen_string_literal: true

describe_current do
  let(:enable) { described_class.new.call }

  context "when karafka framework is not initialized" do
    before do
      Karafka::App.config.internal.status.stubs(:initializing?).returns(true)
    end

    it "expect not to allow for enabling of web-ui" do
      assert_raises(Karafka::Web::Errors::KarafkaNotInitializedError) { enable }
    end
  end

  context "when tracking is active" do
    let(:ui_listener) { stub }
    let(:routes) { stub }
    let(:karafka_monitor) { stub }
    let(:app_monitor) { stub }

    before do
      # Config mocks
      Karafka::Web.config.stubs(:enabled).returns(false, true)
      Karafka::Web.config.stubs(:enabled=)

      Karafka::Web.config.tracking.stubs(:active).returns(nil, true)
      Karafka::Web.config.tracking.stubs(:active=)

      # Mock listeners config
      Karafka::Web.config.tracking.ui.stubs(:listeners).returns([ui_listener])
      Karafka::Web.config.tracking.consumers.stubs(:listeners).returns([])
      Karafka::Web.config.tracking.producers.stubs(:listeners).returns([])

      # Mock routing and monitors
      routes.stubs(:draw)
      karafka_monitor.stubs(:subscribe)
      app_monitor.stubs(:subscribe)

      Karafka::App.stubs(:routes).returns(routes)
      Karafka::App.stubs(:monitor).returns(app_monitor)
      Karafka.stubs(:monitor).returns(karafka_monitor)
    end

    it "expect to subscribe UI listeners to Karafka monitor" do
      karafka_monitor.expects(:subscribe).with(ui_listener)
      enable
    end
  end

  context "when tracking is not active" do
    let(:routes) { stub }
    let(:karafka_monitor) { stub }

    before do
      Karafka::Web.config.stubs(:enabled).returns(false, true)
      Karafka::Web.config.stubs(:enabled=)

      Karafka::Web.config.tracking.stubs(:active).returns(nil, false)
      Karafka::Web.config.tracking.stubs(:active=)

      routes.stubs(:draw)
      karafka_monitor.stubs(:subscribe)

      Karafka::App.stubs(:routes).returns(routes)
      Karafka.stubs(:monitor).returns(karafka_monitor)
    end

    it "expect not to subscribe any listeners" do
      karafka_monitor.expects(:subscribe).never
      enable
    end
  end
end
