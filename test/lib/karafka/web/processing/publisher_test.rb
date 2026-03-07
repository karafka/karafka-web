# frozen_string_literal: true

describe_current do
  let(:consumers_state) do
    {
      schema_version: "1.4.0",
      dispatched_at: Time.now.to_f,
      schema_state: "compatible",
      stats: { messages: 100 },
      processes: {}
    }
  end

  let(:consumers_metrics) do
    {
      schema_version: "1.3.0",
      dispatched_at: Time.now.to_f,
      aggregated: { days: [], hours: [], minutes: [], seconds: [] },
      consumer_groups: { days: [], hours: [], minutes: [], seconds: [] }
    }
  end

  let(:producer) { stub }

  before do
    Karafka::Web.stubs(:producer).returns(producer)
  end

  describe ".publish" do
    it "publishes data asynchronously" do
      producer.stubs(:produce_many_async)

      producer.expects(:produce_many_async).with(instance_of(Array))
      described_class.publish(consumers_state, consumers_metrics)
    end

    it "compresses the state payload with zlib" do
      producer.expects(:produce_many_sync).with(instance_of(Array))
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      state_message = expected_messages[0]

      assert_equal({ "zlib" => "true" }, state_message[:headers])

      decompressed = Zlib::Inflate.inflate(state_message[:payload])

      assert_equal(consumers_state, JSON.parse(decompressed, symbolize_names: true))
    end

    it "compresses the metrics payload with zlib" do
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      metrics_message = expected_messages[1]

      assert_equal({ "zlib" => "true" }, metrics_message[:headers])

      decompressed = Zlib::Inflate.inflate(metrics_message[:payload])

      assert_equal(consumers_metrics, JSON.parse(decompressed, symbolize_names: true))
    end

    it "uses correct topics" do
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      assert_equal(Karafka::Web.config.topics.consumers.states.name, expected_messages[0][:topic])
      assert_equal(Karafka::Web.config.topics.consumers.metrics.name, expected_messages[1][:topic])
    end

    it "uses topic names as keys for compaction" do
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      assert_equal(Karafka::Web.config.topics.consumers.states.name, expected_messages[0][:key])
      assert_equal(Karafka::Web.config.topics.consumers.metrics.name, expected_messages[1][:key])
    end

    it "publishes to partition 0" do
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      assert_equal(0, expected_messages[0][:partition])
      assert_equal(0, expected_messages[1][:partition])
    end
  end

  describe ".publish!" do
    it "publishes data synchronously" do
      producer.stubs(:produce_many_sync)

      described_class.publish!(consumers_state, consumers_metrics)
    end

    it "compresses the payloads with zlib" do
      expected_messages = []

      producer.stubs(:produce_many_sync).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_sync) do |messages| expected_messages = messages end

      described_class.publish!(consumers_state, consumers_metrics)

      state_message = expected_messages[0]
      metrics_message = expected_messages[1]

      assert_equal({ "zlib" => "true" }, state_message[:headers])
      assert_equal({ "zlib" => "true" }, metrics_message[:headers])
    end

    it "uses correct topics and keys" do
      expected_messages = []

      producer.stubs(:produce_many_sync).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_sync) do |messages| expected_messages = messages end

      described_class.publish!(consumers_state, consumers_metrics)

      assert_equal(Karafka::Web.config.topics.consumers.states.name, expected_messages[0][:topic])
      assert_equal(Karafka::Web.config.topics.consumers.states.name, expected_messages[0][:key])
      assert_equal(Karafka::Web.config.topics.consumers.metrics.name, expected_messages[1][:topic])
      assert_equal(Karafka::Web.config.topics.consumers.metrics.name, expected_messages[1][:key])
    end
  end

  context "when handling large state data" do
    let(:large_processes) do
      100.times.each_with_object({}) do |i, hash|
        hash[:"process_#{i}"] = {
          dispatched_at: Time.now.to_f,
          offset: i * 100
        }
      end
    end

    let(:consumers_state) do
      {
        schema_version: "1.4.0",
        dispatched_at: Time.now.to_f,
        schema_state: "compatible",
        stats: { messages: 100_000 },
        processes: large_processes
      }
    end

    it "compresses large payloads efficiently" do
      expected_messages = []

      producer.stubs(:produce_many_async).with(anything).returns(nil) # TODO: convert do-block stub
      # Original: allow(producer).to receive(:produce_many_async) do |messages| expected_messages = messages end

      described_class.publish(consumers_state, consumers_metrics)

      state_message = expected_messages[0]
      uncompressed_size = consumers_state.to_json.bytesize
      compressed_size = state_message[:payload].bytesize

      assert(compressed_size < uncompressed_size)
    end
  end
end
