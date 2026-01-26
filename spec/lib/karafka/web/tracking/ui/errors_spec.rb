# frozen_string_literal: true

RSpec.describe Karafka::Web::Tracking::Ui::Errors do
  subject(:listener) { described_class.new }

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
          expect(params[:topic]).to eq(Karafka::Web.config.topics.errors.name)
          expect(params[:headers]).to eq("zlib" => "true")

          payload = JSON.parse(Zlib::Inflate.inflate(params[:payload]))
          expect(payload["schema_version"]).to eq("1.2.0")
          expect(payload["id"]).to be_a(String)
          expect(payload["id"]).not_to be_empty
          expect(payload["id"]).to match(uuid_pattern)
          expect(payload["type"]).to eq("web.ui.error")
          expect(payload["error_class"]).to eq("StandardError")
          expect(payload["error_message"]).to eq("UI error message")
          expect(payload["backtrace"]).to be_a(String)
          expect(payload["details"]).to eq({})
          expect(payload["occurred_at"]).to be_a(Float)
          # Process ID format: hostname:pid:random_hex
          expect(payload["process"]["id"].split(":").size).to eq(3)
          expect(payload["process"]["id"]).to match(/^.+:\d+:[a-f0-9]{12}$/)
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

        expect(ids[0]).not_to eq(ids[1])
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
        expect { listener.on_error_occurred(event) }.not_to raise_error

        expect(Karafka.logger).to have_received(:error).with(/Failed to report UI error/)
      end
    end
  end
end
