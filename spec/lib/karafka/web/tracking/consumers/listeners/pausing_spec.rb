# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { ::Karafka::Web.config.tracking.consumers.sampler }
  let(:topic) { build(:routing_topic).name }
  let(:subscription_group) { build(:routing_subscription_group) }
  let(:event) do
    {
      topic: topic,
      partition: 1,
      subscription_group: subscription_group,
      timeout: 2_000
    }
  end

  describe '#on_consumer_consuming_pause' do
    it 'expect to add pause reference' do
      listener.on_consumer_consuming_pause(event)

      expect(sampler.pauses.keys).to include("#{subscription_group.id}-#{topic}-1")
    end
  end

  describe '#on_client_resume' do
    it 'expect to remove added reference' do
      listener.on_consumer_consuming_pause(event)
      listener.on_client_resume(event)

      expect(sampler.pauses).not_to include("#{subscription_group.id}-#{topic}-1")
    end
  end
end
