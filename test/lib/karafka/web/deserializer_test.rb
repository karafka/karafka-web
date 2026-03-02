# frozen_string_literal: true

describe_current do
  let(:parsing) { described_class.new.call(message) }

  let(:message) { instance_double(Karafka::Messages::Message) }
  let(:raw_payload) { '{"key":"value"}' }
  let(:headers) { {} }

  before do
    allow(message).to receive_messages(
      raw_payload: raw_payload,
      headers: headers
    )
  end

  context "when JSON is parsed successfully" do
    it "returns a hash" do
      assert_kind_of(Hash, parsing)
    end

    it "returns a hash with symbolized keys" do
      assert_equal(true, parsing.keys.all?(Symbol))
    end

    it "returns a hash with expected values" do
      assert_equal({ key: "value" }, parsing)
    end
  end

  context "when JSON parsing fails" do
    let(:raw_payload) { "invalid json" }

    it "raises a JSON::ParserError" do
      assert_raises(JSON::ParserError) { parsing }
    end
  end

  context "when we detect zlib usage" do
    let(:headers) { { "zlib" => "true" } }
    let(:raw_payload) { Zlib::Deflate.deflate('{"key":"value"}') }

    context "when JSON is parsed successfully" do
      it "returns a hash" do
        assert_kind_of(Hash, parsing)
      end

      it "returns a hash with symbolized keys" do
        assert_equal(true, parsing.keys.all?(Symbol))
      end

      it "returns a hash with expected values" do
        assert_equal({ key: "value" }, parsing)
      end
    end

    context "when JSON parsing fails" do
      let(:raw_payload) { Zlib::Deflate.deflate("invalid json") }

      it "raises a JSON::ParserError" do
        assert_raises(JSON::ParserError) { parsing }
      end
    end

    context "when data is not compressed" do
      let(:raw_payload) { "not compressed" }

      it "raises a Zlib::DataError" do
        assert_raises(Zlib::DataError) { parsing }
      end
    end
  end

  context "when JSON contains duplicate keys" do
    let(:raw_payload) { '{"processes":{"key1":"value1","key1":"value2"},"other":"data"}' }

    it "allows duplicate keys and uses the last value" do
      assert_equal({ processes: { key1: "value2" }, other: "data" }, parsing)
    end

    it "returns a hash with symbolized keys" do
      assert_equal(true, parsing.keys.all?(Symbol))
    end

    context "when duplicate keys exist at nested levels" do
      let(:raw_payload) do
        '{"processes":{"process1":{"id":"abc","id":"def"},"process1":{"id":"ghi"}}}'
      end

      it "handles nested duplicates correctly" do
        assert_equal({ processes: { process1: { id: "ghi" } } }, parsing)
      end
    end

    context "when duplicate keys exist with compressed data" do
      let(:headers) { { "zlib" => "true" } }
      let(:raw_payload) do
        Zlib::Deflate.deflate('{"processes":{"key1":"value1","key1":"value2"}}')
      end

      it "allows duplicate keys with compressed payload" do
        assert_equal({ processes: { key1: "value2" } }, parsing)
      end
    end

    context "when duplicate process IDs exist (bug #741 case)" do
      let(:raw_payload) do
        # Simulating the actual bug case where process IDs could be duplicated
        '{"processes":{"worker-123":{"offset":100},"worker-123":{"offset":200}},"stats":{}}'
      end

      it "handles duplicate process IDs by keeping the last occurrence" do
        result = parsing
        assert_equal({ "worker-123": { offset: 200 } }, result[:processes])
        assert_equal(1, result[:processes].keys.count)
      end

      it "maintains other data intact" do
        result = parsing
        assert_equal({}, result[:stats])
      end
    end
  end
end
