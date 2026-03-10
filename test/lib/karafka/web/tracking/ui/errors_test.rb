# frozen_string_literal: true

describe Karafka::Web::Tracking::Ui::Errors do
  let(:listener) { described_class.new }

  let(:producer) { stub }
  let(:error) { StandardError.new("UI error message") }
  let(:event) do
    {
      type: "web.ui.error",
      error: error,
      caller: nil
    }
  end

  before do
    Karafka::Web.stubs(:producer).returns(producer)
    producer.stubs(:produce_async)
  end

  describe "#on_error_occurred" do
    context "when the event type is web.ui.error" do
      let(:uuid_pattern) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i }

      it "expect to dispatch error to Kafka" do
        captured_params = nil
        producer.stubs(:produce_async).with { |params|
          captured_params = params
          true
        }

        listener.on_error_occurred(event)

        refute_nil(captured_params, "produce_async should have been called")
        assert_equal(Karafka::Web.config.topics.errors.name, captured_params[:topic])
        assert_equal({ "zlib" => "true" }, captured_params[:headers])

        payload = JSON.parse(Zlib::Inflate.inflate(captured_params[:payload]))

        assert_equal("1.2.0", payload["schema_version"])
        assert_kind_of(String, payload["id"])
        refute_empty(payload["id"])
        assert_match(uuid_pattern, payload["id"])
        assert_equal("web.ui.error", payload["type"])
        assert_equal("StandardError", payload["error_class"])
        assert_equal("UI error message", payload["error_message"])
        assert_kind_of(String, payload["backtrace"])
        assert_equal({}, payload["details"])
        assert_kind_of(Float, payload["occurred_at"])
        # Process ID format: hostname:pid:random_hex
        assert_equal(3, payload["process"]["id"].split(":").size)
        assert_match(/^.+:\d+:[a-f0-9]{12}$/, payload["process"]["id"])
      end

      it "expect each error to have a unique id" do
        captured_calls = []
        producer.stubs(:produce_async).with { |params|
          captured_calls << params
          true
        }

        listener.on_error_occurred(event)
        listener.on_error_occurred(event)

        assert_equal(2, captured_calls.size, "produce_async should have been called twice")

        ids = captured_calls.map do |params|
          payload = JSON.parse(Zlib::Inflate.inflate(params[:payload]))
          payload["id"]
        end

        refute_equal(ids[1], ids[0])
      end
    end

    context "when the event type is not web.ui.error" do
      before { event[:type] = "some.other.error" }

      it "expect not to dispatch to Kafka" do
        producer.expects(:produce_async).never
        listener.on_error_occurred(event)
      end
    end

    context "when dispatch fails" do
      before do
        producer.stubs(:produce_async).raises(StandardError, "Kafka unavailable")
      end

      it "expect to log the error and not raise" do
        Karafka.logger.expects(:error).with(regexp_matches(/Failed to report UI error/))
        listener.on_error_occurred(event)
      end
    end
  end
end
