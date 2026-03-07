# frozen_string_literal: true

describe Karafka::Web::Tracking::Ui::Errors do
  let(:listener) { described_class.new }

  let(:producer) { instance_double(WaterDrop::Producer) }
  let(:error) { StandardError.new("UI error message") }
  let(:event) do
    {
      type: "web.ui.error",
      error: error,
      caller: nil
    }
  end

  before do
    allow(Karafka::Web).to receive(:producer).and_return(producer)
    allow(producer).to receive(:produce_async)
  end

  describe "#on_error_occurred" do
    context "when the event type is web.ui.error" do
      let(:uuid_pattern) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i }

      it "expect to dispatch error to Kafka" do
        listener.on_error_occurred(event)

        expect(producer).to have_received(:produce_async) do |params|
          assert_equal(Karafka::Web.config.topics.errors.name, params[:topic])
          assert_equal({ "zlib" => "true" }, params[:headers])

          payload = JSON.parse(Zlib::Inflate.inflate(params[:payload]))

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
      end

      it "expect each error to have a unique id" do
        listener.on_error_occurred(event)
        listener.on_error_occurred(event)

        ids = []
        expect(producer).to have_received(:produce_async).twice do |params|
          payload = JSON.parse(Zlib::Inflate.inflate(params[:payload]))
          ids << payload["id"]
        end

        refute_equal(ids[1], ids[0])
      end
    end

    context "when the event type is not web.ui.error" do
      before { event[:type] = "some.other.error" }

      it "expect not to dispatch to Kafka" do
        listener.on_error_occurred(event)

        expect(producer).not_to have_received(:produce_async)
      end
    end

    context "when dispatch fails" do
      before do
        allow(producer).to receive(:produce_async).and_raise(StandardError, "Kafka unavailable")
        allow(Karafka.logger).to receive(:error)
      end

      it "expect to log the error and not raise" do
        listener.on_error_occurred(event)

        expect(Karafka.logger).to have_received(:error).with(/Failed to report UI error/)
      end
    end
  end
end
