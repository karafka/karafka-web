# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { instance_double(Karafka::Web::Tracking::Consumers::Sampler) }
  let(:consumer_groups) { {} }
  let(:subscription_groups) { {} }
  let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
  let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup) }
  let(:sg_id) { "subscription_group_1" }
  let(:cg_id) { "consumer_group_1" }

  before do
    allow(Karafka::Web.config.tracking.consumers)
      .to receive(:sampler)
      .and_return(sampler)

    allow(sampler)
      .to receive_messages(
        consumer_groups: consumer_groups,
        subscription_groups: subscription_groups
      )

    allow(subscription_group)
      .to receive_messages(
        id: sg_id,
        consumer_group: consumer_group,
        kafka: {}
      )

    allow(consumer_group)
      .to receive(:id)
      .and_return(cg_id)

    # Mock the nested structure for consumer groups
    consumer_groups[cg_id] = { subscription_groups: {} }
  end

  describe "#on_connection_listener_before_fetch_loop" do
    let(:event) do
      { subscription_group: subscription_group }
    end

    it "initializes subscription group in sampler when fetch loop starts" do
      allow(sampler).to receive(:track).and_yield(sampler)
      allow(subscription_groups).to receive(:[]).with(sg_id).and_return({})

      listener.on_connection_listener_before_fetch_loop(event)

      expect(sampler).to have_received(:track)
    end

    it "calls track with correct subscription group id" do
      yielded_sampler = nil

      allow(sampler).to receive(:track) do |&block|
        yielded_sampler = sampler
        block.call(sampler)
      end

      allow(subscription_groups).to receive(:[]).with(sg_id).and_return({})

      listener.on_connection_listener_before_fetch_loop(event)

      expect(sampler).to have_received(:track)
      expect(yielded_sampler).to eq(sampler)
    end

    it "accesses subscription group by id in the track block" do
      allow(sampler).to receive(:track).and_yield(sampler)
      allow(subscription_groups).to receive(:[]).with(sg_id).and_return({})

      listener.on_connection_listener_before_fetch_loop(event)

      expect(sampler).to have_received(:track)
      expect(subscription_groups).to have_received(:[]).with(sg_id)
    end

    context "when group.instance.id is configured" do
      before do
        allow(subscription_group)
          .to receive(:kafka)
          .and_return({ "group.instance.id": "my-static-instance" })

        allow(sampler)
          .to receive(:track)
          .and_yield(sampler)

        subscription_groups[sg_id] = {}
      end

      it "stores the instance_id in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(subscription_groups[sg_id][:instance_id]).to eq("my-static-instance")
      end
    end

    context "when group.instance.id is not configured" do
      before do
        allow(subscription_group).to receive(:kafka).and_return({})
        allow(sampler).to receive(:track).and_yield(sampler)
        subscription_groups[sg_id] = {}
      end

      it "stores false for instance_id in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(subscription_groups[sg_id][:instance_id]).to be(false)
      end
    end
  end

  describe "#on_connection_listener_after_fetch_loop" do
    let(:event) do
      { subscription_group: subscription_group }
    end

    before do
      # Setup the nested structure that would exist
      consumer_groups[cg_id][:subscription_groups][sg_id] = { some: "data" }
      subscription_groups[sg_id] = { polled_at: Time.now }
    end

    it "removes subscription group from consumer group and sampler when fetch loop ends" do
      allow(sampler).to receive(:track).and_yield(sampler)

      listener.on_connection_listener_after_fetch_loop(event)

      expect(sampler).to have_received(:track)
      # Verify the deletions happened
      expect(consumer_groups[cg_id][:subscription_groups]).not_to have_key(sg_id)
      expect(subscription_groups).not_to have_key(sg_id)
    end

    it "cleans up subscription group data properly" do
      allow(sampler).to receive(:track).and_yield(sampler)
      allow(consumer_groups[cg_id][:subscription_groups]).to receive(:delete).with(sg_id)
      allow(subscription_groups).to receive(:delete).with(sg_id)

      listener.on_connection_listener_after_fetch_loop(event)

      expect(sampler).to have_received(:track)
      expect(consumer_groups[cg_id][:subscription_groups]).to have_received(:delete).with(sg_id)
      expect(subscription_groups).to have_received(:delete).with(sg_id)
    end

    context "when subscription group is not present" do
      before do
        consumer_groups[cg_id][:subscription_groups].clear
        subscription_groups.clear
      end

      it "handles missing subscription group gracefully" do
        allow(sampler).to receive(:track).and_yield(sampler)

        expect { listener.on_connection_listener_after_fetch_loop(event) }.not_to raise_error

        expect(sampler).to have_received(:track)
      end
    end
  end

  describe "#on_connection_listener_fetch_loop_received" do
    let(:event) do
      { subscription_group: subscription_group }
    end

    before do
      subscription_groups[sg_id] = {}
    end

    it "updates polled_at timestamp when poll is received" do
      current_time = nil
      allow(sampler).to receive(:track) do |&block|
        current_time = listener.monotonic_now
        allow(listener).to receive(:monotonic_now).and_return(current_time)
        block.call(sampler)
      end

      listener.on_connection_listener_fetch_loop_received(event)

      expect(sampler).to have_received(:track)
      expect(subscription_groups[sg_id][:polled_at]).to eq(current_time)
    end

    it "uses monotonic time for polled_at timestamp" do
      allow(listener).to receive(:monotonic_now).and_call_original
      allow(sampler).to receive(:track).and_yield(sampler)

      listener.on_connection_listener_fetch_loop_received(event)

      expect(listener).to have_received(:monotonic_now)
      expect(sampler).to have_received(:track)
    end

    it "updates existing subscription group data" do
      subscription_groups[sg_id][:existing_data] = "preserved"
      allow(sampler).to receive(:track).and_yield(sampler)

      listener.on_connection_listener_fetch_loop_received(event)

      expect(sampler).to have_received(:track)
      expect(subscription_groups[sg_id][:existing_data]).to eq("preserved")
      expect(subscription_groups[sg_id][:polled_at]).to be_a(Float)
    end

    context "when subscription group does not exist" do
      before do
        subscription_groups.delete(sg_id)
      end

      it "creates the subscription group entry" do
        allow(sampler).to receive(:track).and_yield(sampler)
        allow(subscription_groups).to receive(:[]).with(sg_id).and_return({})

        listener.on_connection_listener_fetch_loop_received(event)

        expect(sampler).to have_received(:track)
      end
    end
  end

  describe "inheritance from Base" do
    it "inherits from Base listener" do
      expect(described_class.superclass).to eq(Karafka::Web::Tracking::Consumers::Listeners::Base)
    end

    it "has access to base class methods" do
      expect(listener).to respond_to(:track)
      expect(listener).to respond_to(:report)
      expect(listener).to respond_to(:report!)
    end

    it "has access to time helper methods from base" do
      expect(listener).to respond_to(:monotonic_now)
      expect(listener).to respond_to(:float_now)
    end
  end

  describe "integration scenarios" do
    let(:event_before) { { subscription_group: subscription_group } }
    let(:event_received) { { subscription_group: subscription_group } }
    let(:event_after) { { subscription_group: subscription_group } }

    before do
      # Setup proper tracking calls
      allow(sampler).to receive(:track).and_yield(sampler)
      subscription_groups[sg_id] = {}
      consumer_groups[cg_id][:subscription_groups][sg_id] = {}
    end

    it "handles complete fetch loop lifecycle" do
      # Before fetch loop - initialize
      listener.on_connection_listener_before_fetch_loop(event_before)

      # During fetch loop - update polled_at
      listener.on_connection_listener_fetch_loop_received(event_received)
      expect(subscription_groups[sg_id][:polled_at]).to be_a(Float)

      # After fetch loop - cleanup
      listener.on_connection_listener_after_fetch_loop(event_after)
      expect(subscription_groups).not_to have_key(sg_id)
      expect(consumer_groups[cg_id][:subscription_groups]).not_to have_key(sg_id)
    end

    it "handles multiple polling events during fetch loop" do
      listener.on_connection_listener_before_fetch_loop(event_before)

      first_time = listener.monotonic_now
      allow(listener).to receive(:monotonic_now).and_return(first_time)
      listener.on_connection_listener_fetch_loop_received(event_received)

      second_time = first_time + 1.0
      allow(listener).to receive(:monotonic_now).and_return(second_time)
      listener.on_connection_listener_fetch_loop_received(event_received)

      expect(subscription_groups[sg_id][:polled_at]).to eq(second_time)
    end
  end

  describe "error handling" do
    let(:event) { { subscription_group: subscription_group } }

    context "when sampler tracking fails" do
      before do
        allow(sampler).to receive(:track).and_raise(StandardError, "Sampler error")
      end

      it "allows errors to propagate from before_fetch_loop" do
        expect { listener.on_connection_listener_before_fetch_loop(event) }
          .to raise_error(StandardError, "Sampler error")
      end

      it "allows errors to propagate from after_fetch_loop" do
        expect { listener.on_connection_listener_after_fetch_loop(event) }
          .to raise_error(StandardError, "Sampler error")
      end

      it "allows errors to propagate from fetch_loop_received" do
        expect { listener.on_connection_listener_fetch_loop_received(event) }
          .to raise_error(StandardError, "Sampler error")
      end
    end
  end
end
