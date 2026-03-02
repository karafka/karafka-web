# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:event) { Struct.new(:payload).new({ caller: consumer }) }
  let(:coordinator) { build(:processing_coordinator, topic: topic) }
  let(:topic) { build(:routing_topic) }
  let(:consumer) { build(:consumer, coordinator: coordinator) }

  before do
    coordinator.pause_tracker.increment
    listener.on_consumer_consume(event)
  end

  it { assert_equal([], consumer.tags.to_a) }

  context "when it is active job work" do
    before do
      allow(topic).to receive(:active_job?).and_return(true)
      listener.on_consumer_consume(event)
    end

    it { assert_equal(%w[active_job], consumer.tags.to_a) }
  end

  context "when it is the first attempt" do
    it { refute_includes(consumer.tags.to_a, "attempt: 1") }
  end

  context "when it is another attempt" do
    before do
      coordinator.pause_tracker.increment
      listener.on_consumer_consume(event)
    end

    it { assert_includes(consumer.tags.to_a, "attempt: 2") }
  end
end
