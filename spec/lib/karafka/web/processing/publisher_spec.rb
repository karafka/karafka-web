# frozen_string_literal: true

RSpec.describe_current do
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

  let(:producer) { instance_double(WaterDrop::Producer) }

  before do
    allow(Karafka::Web).to receive(:producer).and_return(producer)
  end

  describe ".publish" do
    it "publishes data asynchronously" do
      allow(producer).to receive(:produce_many_async)

      described_class.publish(consumers_state, consumers_metrics)

      expect(producer).to have_received(:produce_many_async).with(
        an_instance_of(Array)
      )
    end

    it "compresses the state payload with zlib" do
      expected_messages = []

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      state_message = expected_messages[0]
      expect(state_message[:headers]).to eq({ "zlib" => "true" })

      decompressed = Zlib::Inflate.inflate(state_message[:payload])
      expect(JSON.parse(decompressed, symbolize_names: true)).to eq(consumers_state)
    end

    it "compresses the metrics payload with zlib" do
      expected_messages = []

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      metrics_message = expected_messages[1]
      expect(metrics_message[:headers]).to eq({ "zlib" => "true" })

      decompressed = Zlib::Inflate.inflate(metrics_message[:payload])
      expect(JSON.parse(decompressed, symbolize_names: true)).to eq(consumers_metrics)
    end

    it "uses correct topics" do
      expected_messages = []

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      expect(expected_messages[0][:topic]).to eq(Karafka::Web.config.topics.consumers.states.name)
      expect(expected_messages[1][:topic]).to eq(Karafka::Web.config.topics.consumers.metrics.name)
    end

    it "uses topic names as keys for compaction" do
      expected_messages = []

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      expect(expected_messages[0][:key]).to eq(Karafka::Web.config.topics.consumers.states.name)
      expect(expected_messages[1][:key]).to eq(Karafka::Web.config.topics.consumers.metrics.name)
    end

    it "publishes to partition 0" do
      expected_messages = []

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      expect(expected_messages[0][:partition]).to eq(0)
      expect(expected_messages[1][:partition]).to eq(0)
    end
  end

  describe ".publish!" do
    it "publishes data synchronously" do
      allow(producer).to receive(:produce_many_sync)

      described_class.publish!(consumers_state, consumers_metrics)

      expect(producer).to have_received(:produce_many_sync).with(
        an_instance_of(Array)
      )
    end

    it "compresses the payloads with zlib" do
      expected_messages = []

      allow(producer).to receive(:produce_many_sync) do |messages|
        expected_messages = messages
      end

      described_class.publish!(consumers_state, consumers_metrics)

      state_message = expected_messages[0]
      metrics_message = expected_messages[1]

      expect(state_message[:headers]).to eq({ "zlib" => "true" })
      expect(metrics_message[:headers]).to eq({ "zlib" => "true" })
    end

    it "uses correct topics and keys" do
      expected_messages = []

      allow(producer).to receive(:produce_many_sync) do |messages|
        expected_messages = messages
      end

      described_class.publish!(consumers_state, consumers_metrics)

      expect(expected_messages[0][:topic]).to eq(Karafka::Web.config.topics.consumers.states.name)
      expect(expected_messages[0][:key]).to eq(Karafka::Web.config.topics.consumers.states.name)
      expect(expected_messages[1][:topic]).to eq(Karafka::Web.config.topics.consumers.metrics.name)
      expect(expected_messages[1][:key]).to eq(Karafka::Web.config.topics.consumers.metrics.name)
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

      allow(producer).to receive(:produce_many_async) do |messages|
        expected_messages = messages
      end

      described_class.publish(consumers_state, consumers_metrics)

      state_message = expected_messages[0]
      uncompressed_size = consumers_state.to_json.bytesize
      compressed_size = state_message[:payload].bytesize

      expect(compressed_size).to be < uncompressed_size
    end
  end
end
