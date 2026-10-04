# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  describe "#active?" do
    context "when producer is not yet created" do
      before { Karafka.stubs(:producer).returns(nil) }

      it { refute(reporter.active?) }
    end

    context "when producer is not active" do
      before { Karafka.producer.status.stubs(:active?).returns(false) }

      it { refute(reporter.active?) }
    end

    context "when producer exists but karafka is not even initializing" do
      before { Karafka::App.stubs(:initializing?).returns(true) }

      it { refute(reporter.active?) }
    end

    context "when producer exists but karafka is not initialized" do
      before do
        Karafka::App.stubs(:initializing?).returns(false)
        Karafka::App.stubs(:initialized?).returns(true)
      end

      it { refute(reporter.active?) }
    end

    context "when producer exists and is active and server is running" do
      before do
        Karafka::App.stubs(:initializing?).returns(false)
        Karafka::App.stubs(:initialized?).returns(false)
      end

      it { assert(reporter.active?) }
    end
  end

  describe "#produce" do
    let(:producer) { Karafka::Web.producer }
    let(:messages) { Array.new(sync_threshold) { { topic: "topic", payload: "payload" } } }
    let(:sync_threshold) { Karafka::Web.config.tracking.consumers.sync_threshold }

    context "when the sync dispatch fails" do
      it "expect to log the failure instead of raising" do
        producer.stubs(:produce_many_sync).raises(WaterDrop::Errors::ProduceManyError.new([], "msg_timed_out"))
        Karafka.logger.expects(:error).with(regexp_matches(/Failed to report consumers state: .*ProduceManyError - msg_timed_out/))

        assert_output("") { reporter.send(:produce, messages) }
      end
    end

    context "when the async dispatch fails" do
      it "expect to log the failure instead of raising" do
        producer.stubs(:produce_many_async).raises(WaterDrop::Errors::ProduceManyError.new([], "boom"))
        Karafka.logger.expects(:error).with(regexp_matches(/Failed to report consumers state: .*ProduceManyError - boom/))

        assert_output("") { reporter.send(:produce, messages.first(1)) }
      end
    end

    context "when the dispatch fails with an error not originating from the produce" do
      it "expect not to silence it" do
        producer.stubs(:produce_many_sync).raises(StandardError.new("other"))
        Karafka.logger.expects(:error).never

        assert_raises(StandardError) { reporter.send(:produce, messages) }
      end
    end

    context "when the producer is already closed" do
      it "expect to ignore it silently" do
        producer.stubs(:produce_many_sync).raises(WaterDrop::Errors::ProducerClosedError.new("closed"))
        Karafka.logger.expects(:error).never

        assert_output("") { reporter.send(:produce, messages) }
      end
    end
  end
end
