# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
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

  describe "#on_client_pause" do
    it "expect to add pause reference" do
      listener.on_client_pause(event)

      assert_includes(sampler.pauses.keys, "#{subscription_group.id}-#{topic}-1")
    end
  end

  describe "#on_client_resume" do
    it "expect to remove added reference" do
      listener.on_client_pause(event)
      listener.on_client_resume(event)

      refute_includes(sampler.pauses, "#{subscription_group.id}-#{topic}-1")
    end
  end
end
