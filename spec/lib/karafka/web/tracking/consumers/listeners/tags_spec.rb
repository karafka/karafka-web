# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:event) { OpenStruct.new(payload: { caller: consumer }) }
  let(:coordinator) { build(:processing_coordinator, topic: topic) }
  let(:topic) { build(:routing_topic) }
  let(:consumer) do
    consumer = Karafka::BaseConsumer.new
    consumer.coordinator = coordinator
    consumer
  end

  before do
    coordinator.pause_tracker.increment
    allow(consumer).to receive(:coordinator).and_return(coordinator)
    listener.on_consumer_consume(event)
  end

  it { expect(consumer.tags.to_a).to eq([]) }

  context 'when it is active job work' do
    before do
      allow(topic).to receive(:active_job?).and_return(true)
      listener.on_consumer_consume(event)
    end

    it { expect(consumer.tags.to_a).to eq(%w[active_job]) }
  end

  context 'when it is the first attempt' do
    it { expect(consumer.tags.to_a).not_to include('attempt:1') }
  end

  context 'when it is another attempt' do
    before do
      coordinator.pause_tracker.increment
      listener.on_consumer_consume(event)
    end

    it { expect(consumer.tags.to_a).to include('attempt:2') }
  end
end
