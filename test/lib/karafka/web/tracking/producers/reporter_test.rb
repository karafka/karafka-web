# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  let(:producer) { WaterDrop::Producer.new }
  let(:sampler) { Karafka::Web.config.tracking.producers.sampler }
  let(:errors_topic) { generate_topic_name }
  let(:valid_error) do
    {
      schema_version: "1.0.0",
      id: SecureRandom.uuid,
      type: "librdkafka.dispatch_error",
      error_class: "StandardError",
      error_message: "Raised",
      backtrace: "lib/file.rb",
      details: {},
      occurred_at: Time.now.to_f,
      process: { id: "my-process" }
    }
  end

  before do
    Karafka::Web.config.topics.errors.name = errors_topic
    Karafka::Web.stubs(:producer).returns(producer)
    producer.status.stubs(:active?).returns(true)
    Karafka::Web.producer.stubs(:produce_many_sync)
    Karafka::Web.producer.stubs(:produce_many_async)
  end

  context "when there is nothing to report" do
    it "expect not to dispatch any messages" do
      Karafka::Web.producer.expects(:produce_many_sync).never
      Karafka::Web.producer.expects(:produce_many_async).never
      reporter.report
    end
  end

  context "when there is a report but it is not yet time to dispatch due to previous dispatch" do
    before do
      reporter.report
      sampler.errors << valid_error
    end

    it "expect not to dispatch any messages yet" do
      Karafka::Web.producer.expects(:produce_many_sync).never
      Karafka::Web.producer.expects(:produce_many_async).never
      reporter.report
    end
  end

  context "when we have error to report and it is time" do
    context "when errot data does not comply with the expected schema" do
      before { sampler.errors << {} }

      it do
        assert_raises(Karafka::Web::Errors::ContractError) { reporter.report }
      end
    end

    context "when there is less than 25 of errors" do
      before { sampler.errors << valid_error }

      it "expect to dispatch via async" do
        reporter.report

        producer.expects(:produce_many_async).with([{ key: "my-process", payload: valid_error.to_json, topic: errors_topic }]) # MOCHA_REORDER
      end
    end

    context "when there is more than 25 errors" do
      let(:dispatch) do
        Array.new(26) do
          { key: "my-process", payload: valid_error.to_json, topic: errors_topic }
        end
      end

      before { 26.times { sampler.errors << valid_error } }

      it "expect to dispatch via sync" do
        reporter.report

        producer.expects(:produce_many_sync).with(dispatch) # MOCHA_REORDER
      end
    end

    context "when dispatch is done" do
      before do
        sampler.errors << valid_error
        reporter.report
      end

      it "expect to clear the dispatcher errors accumulator" do
        assert_empty(sampler.errors)
      end
    end
  end

  describe "#active?" do
    context "when producer is not yet created" do
      before { Karafka::Web.stubs(:producer).returns(nil) }

      it { refute(reporter.active?) }
    end

    context "when producer is not active" do
      before { Karafka::Web.producer.status.stubs(:active?).returns(false) }

      it { refute(reporter.active?) }
    end

    context "when producer exists and is active" do
      it { assert(reporter.active?) }
    end
  end
end
