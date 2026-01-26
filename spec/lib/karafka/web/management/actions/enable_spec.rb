# frozen_string_literal: true

RSpec.describe_current do
  subject(:enable) { described_class.new.call }

  context "when karafka framework is not initialized" do
    before do
      allow(Karafka::App.config.internal.status)
        .to receive(:initializing?)
        .and_return(true)
    end

    it "expect not to allow for enabling of web-ui" do
      expect { enable }.to raise_error(Karafka::Web::Errors::KarafkaNotInitializedError)
    end
  end

  context "when tracking is active" do
    let(:ui_listener) { instance_double(Karafka::Web::Tracking::Ui::Errors) }
    let(:routes) { instance_double(Karafka::Routing::Builder) }
    let(:karafka_monitor) { instance_double(Karafka::Instrumentation::Monitor) }
    let(:app_monitor) { instance_double(Karafka::Instrumentation::Monitor) }

    before do
      # Config mocks
      allow(Karafka::Web.config).to receive(:enabled).and_return(false, true)
      allow(Karafka::Web.config).to receive(:enabled=)

      allow(Karafka::Web.config.tracking).to receive(:active).and_return(nil, true)
      allow(Karafka::Web.config.tracking).to receive(:active=)

      # Mock listeners config
      allow(Karafka::Web.config.tracking.ui).to receive(:listeners).and_return([ui_listener])
      allow(Karafka::Web.config.tracking.consumers).to receive(:listeners).and_return([])
      allow(Karafka::Web.config.tracking.producers).to receive(:listeners).and_return([])

      # Mock routing and monitors
      allow(routes).to receive(:draw)
      allow(karafka_monitor).to receive(:subscribe)
      allow(app_monitor).to receive(:subscribe)

      allow(Karafka::App).to receive_messages(routes: routes, monitor: app_monitor)
      allow(Karafka).to receive(:monitor).and_return(karafka_monitor)
    end

    it "expect to subscribe UI listeners to Karafka monitor" do
      enable

      expect(karafka_monitor).to have_received(:subscribe).with(ui_listener)
    end
  end

  context "when tracking is not active" do
    let(:routes) { instance_double(Karafka::Routing::Builder) }
    let(:karafka_monitor) { instance_double(Karafka::Instrumentation::Monitor) }

    before do
      allow(Karafka::Web.config).to receive(:enabled).and_return(false, true)
      allow(Karafka::Web.config).to receive(:enabled=)

      allow(Karafka::Web.config.tracking).to receive(:active).and_return(nil, false)
      allow(Karafka::Web.config.tracking).to receive(:active=)

      allow(routes).to receive(:draw)
      allow(karafka_monitor).to receive(:subscribe)

      allow(Karafka::App).to receive(:routes).and_return(routes)
      allow(Karafka).to receive(:monitor).and_return(karafka_monitor)
    end

    it "expect not to subscribe any listeners" do
      enable

      expect(karafka_monitor).not_to have_received(:subscribe)
    end
  end
end
