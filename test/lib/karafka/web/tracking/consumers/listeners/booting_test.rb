# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:scheduler) { Karafka::Web.config.tracking.scheduler }

  let(:event) do
    Karafka::Core::Monitoring::Event.new(
      rand,
      type: "test_type"
    )
  end

  describe "#on_app_running" do
    before { scheduler.stubs(:async_call) }

    it "expect to trigger async call" do
      scheduler.expects(:async_call)
      listener.on_app_running(event)
    end
  end

  describe "#on_swarm_node_after_fork" do
    let(:original_producer) { Karafka::Web.config.producer }

    let(:producer) do
      WaterDrop::Producer.new do |config|
        config.deliver = false
        config.kafka = { "bootstrap.servers": "127.0.0.1:9092", "enable.idempotence": false }
      end
    end

    before do
      original_producer
      Karafka::Web.config.producer = web_producer
      listener.on_swarm_node_after_fork(event)
    end

    after do
      Karafka::Web.config.producer = original_producer
      producer.close
    end

    context "when the Web producer is the default one" do
      let(:web_producer) { Karafka::Web::Producer.new }

      it "expect to keep it as it rebuilds itself after fork" do
        assert_same(web_producer, Karafka::Web.config.producer)
      end

      it "expect to tag the node with its parent pid" do
        assert_includes(Karafka::Process.tags.to_a, "ppid:#{Process.ppid}")
      end
    end

    context "when the Web producer is a dedicated one" do
      let(:web_producer) { producer }

      it "expect to keep it" do
        assert_same(producer, Karafka::Web.config.producer)
      end
    end

    context "when the Web producer is the closed pre-fork app producer" do
      let(:web_producer) { producer.tap(&:close) }

      it "expect to replace it with the node app producer" do
        assert_same(Karafka::App.config.producer, Karafka::Web.config.producer)
      end
    end

    context "when the Web producer is a variant of the closed pre-fork app producer" do
      let(:web_producer) { producer.variant(topic_config: { acks: 0 }).tap(&:close) }

      it "expect to replace it with the node app producer" do
        assert_same(Karafka::App.config.producer, Karafka::Web.config.producer)
      end
    end
  end
end
