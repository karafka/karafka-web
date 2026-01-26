# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:consumer) { build(:consumer) }
  let(:sampler) { Karafka::Web.config.tracking.consumers.sampler }
  let(:subscription_group) { build(:routing_subscription_group) }
  let(:sg_id) { subscription_group.id }
  let(:topic_name) { consumer.topic.name }
  let(:partition_id) { consumer.partition }
  let(:seek_offset) { 100 }
  let(:partition_details) { sampler.subscription_groups[sg_id][:topics][topic_name][partition_id] }

  let(:event) do
    event = Struct
      .new(:type, :caller, :payload)
      .new("consumer.consuming.transaction", consumer, nil)
    event.payload = event
    event
  end

  before do
    allow(consumer.topic)
      .to receive(:subscription_group)
      .and_return(subscription_group)

    allow(consumer.coordinator)
      .to receive(:seek_offset)
      .and_return(seek_offset)

    sampler.subscription_groups[sg_id]
  end

  describe "#on_consumer_consuming_transaction" do
    context "when subscription group exists" do
      before { listener.on_consumer_consuming_transaction(event) }

      it "marks partition as transactional" do
        expect(
          partition_details[:transactional]
        ).to be(true)
      end

      it "sets the seek offset" do
        expect(partition_details[:seek_offset]).to eq(seek_offset)
      end
    end

    context "when subscription group does not exist" do
      before do
        sampler.subscription_groups.clear
        listener.on_consumer_consuming_transaction(event)
      end

      it "does not create new subscription group" do
        expect(sampler.subscription_groups).to be_empty
      end
    end

    context "when seek_offset is nil" do
      let(:seek_offset) { nil }

      before { listener.on_consumer_consuming_transaction(event) }

      it "does not set any partition details and keeps default" do
        expect(partition_details[:seek_offset]).to eq(-1)
      end

      it "does not mark partition as transactional" do
        expect(partition_details[:transactional]).to be(false)
      end
    end

    context "when accessing nested hash structures" do
      before { listener.on_consumer_consuming_transaction(event) }

      it "creates nested structure automatically" do
        partition_data = partition_details
        expect(partition_data).to be_a(Hash)
        expect(partition_data[:transactional]).to be(true)
        expect(partition_data[:seek_offset]).to eq(seek_offset)
      end
    end
  end
end
