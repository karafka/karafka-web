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
    let(:producer_listener) { stub }
    let(:routes) { stub }
    let(:declaratives) { stub }
    let(:karafka_monitor) { stub }
    let(:app_monitor) { stub }
    let(:wd_monitor) { stub }
    let(:producer_monitor) { FakeProducerMonitor.new }
    let(:producer) { stub(monitor: producer_monitor) }

    before do
      # Config mocks
      Karafka::Web.config.stubs(:enabled).returns(false, true)
      Karafka::Web.config.stubs(:enabled=)

      Karafka::Web.config.tracking.stubs(:active).returns(nil, true)
      Karafka::Web.config.tracking.stubs(:active=)

      # Mock listeners config
      Karafka::Web.config.tracking.ui.stubs(:listeners).returns([ui_listener])
      Karafka::Web.config.tracking.consumers.stubs(:listeners).returns([])
      Karafka::Web.config.tracking.producers.stubs(:listeners).returns([producer_listener])

      # Mock routing, declaratives and monitors
      routes.stubs(:draw)
      declaratives.stubs(:draw)
      karafka_monitor.stubs(:subscribe)
      app_monitor.stubs(:subscribe)
      wd_monitor.stubs(:subscribe)

      Karafka::App.stubs(:routes).returns(routes)
      Karafka::App.stubs(:declaratives).returns(declaratives)
      Karafka::App.stubs(:monitor).returns(app_monitor)
      Karafka.stubs(:monitor).returns(karafka_monitor)

      # Producers instrumentation. The default and the Web producer share a single monitor here
      # (in production the Web producer is the default producer or a variant of it), so our
      # listeners should end up subscribed to it only once.
      WaterDrop.stubs(:monitor).returns(wd_monitor)
      Karafka.stubs(:producer).returns(producer)
      Karafka::Web.stubs(:producer).returns(producer)
    end

    it "expect to subscribe UI listeners to Karafka monitor" do
      karafka_monitor.expects(:subscribe).with(ui_listener)
      enable
    end

    it "expect to subscribe to the WaterDrop global producer.configured event" do
      wd_monitor.expects(:subscribe).with("producer.configured")
      enable
    end

    it "expect to subscribe producer listeners to the producer monitor" do
      enable

      assert_equal(1, producer_monitor.subscribed_count(producer_listener))
    end

    context "when the default and Web producers share the same monitor" do
      it "expect not to subscribe the same monitor more than once" do
        enable

        assert_equal(1, producer_monitor.subscribed_count(producer_listener))
      end
    end

    context "when the Web producer uses a separate monitor" do
      let(:web_producer_monitor) { FakeProducerMonitor.new }
      let(:web_producer) { stub(monitor: web_producer_monitor) }

      before do
        Karafka::Web.stubs(:producer).returns(web_producer)
      end

      it "expect to subscribe producer listeners to both monitors once each" do
        enable

        assert_equal(1, producer_monitor.subscribed_count(producer_listener))
        assert_equal(1, web_producer_monitor.subscribed_count(producer_listener))
      end
    end

    context "when a producer listener is already subscribed to the monitor" do
      before do
        # Simulate a user (or an older setup) having wired the Web UI producer tracking to the
        # producer monitor by hand
        producer_monitor.subscribe(producer_listener)
      end

      it "expect not to subscribe it again so errors are not tracked twice" do
        enable

        assert_equal(1, producer_monitor.subscribed_count(producer_listener))
      end
    end

    context "when a producer is announced later via the global monitor" do
      let(:late_producer_monitor) { FakeProducerMonitor.new }
      let(:late_producer) { stub(monitor: late_producer_monitor) }

      before do
        # Capture the block subscribed to `producer.configured` so we can simulate a producer
        # being configured after the Web UI has already been enabled.
        wd_monitor.stubs(:subscribe).with("producer.configured").yields(
          Karafka::Core::Monitoring::Event.new(
            "producer.configured",
            producer: late_producer,
            producer_id: "late"
          )
        )
      end

      it "expect to attach the producer listeners to the newly announced producer" do
        enable

        assert_equal(1, late_producer_monitor.subscribed_count(producer_listener))
      end
    end

    context "when the process is forked" do
      it "expect to subscribe to swarm.node.after_fork to reset the tracking mutex" do
        karafka_monitor.expects(:subscribe).with("swarm.node.after_fork")
        enable
      end

      context "when the after-fork callback fires" do
        before do
          # Simulate a fork by firing the after-fork callback the moment it is registered; the
          # tracking mutex is swapped for a fresh one so the child never inherits a locked one
          karafka_monitor.stubs(:subscribe).with("swarm.node.after_fork").yields
        end

        it "expect producer listeners to still subscribe (fresh, unlocked mutex)" do
          enable

          assert_equal(1, producer_monitor.subscribed_count(producer_listener))
        end
      end
    end
  end

  context "when tracking is not active" do
    let(:routes) { stub }
    let(:declaratives) { stub }
    let(:karafka_monitor) { stub }

    before do
      Karafka::Web.config.stubs(:enabled).returns(false, true)
      Karafka::Web.config.stubs(:enabled=)

      Karafka::Web.config.tracking.stubs(:active).returns(nil, false)
      Karafka::Web.config.tracking.stubs(:active=)

      routes.stubs(:draw)
      declaratives.stubs(:draw)
      karafka_monitor.stubs(:subscribe)

      Karafka::App.stubs(:routes).returns(routes)
      Karafka::App.stubs(:declaratives).returns(declaratives)
      Karafka.stubs(:monitor).returns(karafka_monitor)
    end

    it "expect not to subscribe any listeners" do
      karafka_monitor.expects(:subscribe).never
      enable
    end

    it "expect not to subscribe to the WaterDrop global monitor" do
      WaterDrop.expects(:monitor).never
      enable
    end
  end

  # End-to-end check that the global subscription wired at boot (test_helper enables the Web UI)
  # actually routes producer errors into the Web UI tracking, including for a producer created
  # after the Web UI was enabled - the case the previous per-producer subscription missed.
  context "when a producer is created after the Web UI has been enabled" do
    let(:sampler) { Karafka::Web.config.tracking.producers.sampler }

    let(:producer) do
      WaterDrop::Producer.new do |config|
        config.deliver = false
        config.kafka = { "bootstrap.servers": "127.0.0.1:9092" }
      end
    end

    let(:error) do
      error = StandardError.new("boom")
      error.set_backtrace(caller)
      error
    end

    # Every producer created after the Web UI is enabled now reports into this shared sampler, so
    # we scope assertions to our own producer id instead of the whole sampler to stay isolated
    # from any other producer's errors.
    let(:tracked_errors) { sampler.errors.select { |error| error[:producer_id] == producer.id } }

    before { sampler.clear }

    after { producer.close }

    def dispatch_error
      producer.monitor.instrument(
        "error.occurred",
        producer_id: producer.id,
        type: "librdkafka.dispatch_error",
        error: error,
        topic: "test_topic",
        partition: 0,
        offset: 1
      )
    end

    it "expect its errors to be tracked by the Web UI producers sampler" do
      dispatch_error

      assert_equal(1, tracked_errors.size)
      assert_equal(producer.id, tracked_errors.first[:producer_id])
    end

    it "expect the tracked error to match the error contract" do
      dispatch_error

      schema = Karafka::Web::Tracking::Contracts::Error.new

      assert(schema.call(tracked_errors.first).success?)
    end

    it "expect to track the error exactly once (no double subscription)" do
      dispatch_error

      assert_equal(1, tracked_errors.size)
    end
  end
end
