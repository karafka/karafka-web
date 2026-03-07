# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { stub }
  let(:consumer_groups) { {} }
  let(:subscription_groups) { {} }
  let(:subscription_group) { stub }
  let(:consumer_group) { stub }
  let(:sg_id) { "subscription_group_1" }
  let(:cg_id) { "consumer_group_1" }

  before do
    Karafka::Web.config.tracking.consumers.stubs(:sampler).returns(sampler)

    sampler.stubs(:consumer_groups).returns(consumer_groups)
    sampler.stubs(:subscription_groups).returns(subscription_groups)

    subscription_group.stubs(:id).returns(sg_id)
    subscription_group.stubs(:consumer_group).returns(consumer_group)
    subscription_group.stubs(:kafka).returns({})

    consumer_group.stubs(:id).returns(cg_id)

    # Mock the nested structure for consumer groups
    consumer_groups[cg_id] = { subscription_groups: {} }
  end

  describe "#on_connection_listener_before_fetch_loop" do
    let(:event) do
      { subscription_group: subscription_group }
    end

    it "initializes subscription group in sampler when fetch loop starts" do
      sampler.stubs(:track).yields(sampler)
      subscription_groups.stubs(:[]).with(sg_id).returns({})

      sampler.expects(:track).yields(sampler)
      listener.on_connection_listener_before_fetch_loop(event)
    end

    it "calls track with correct subscription group id" do
      sampler.stubs(:track).yields(sampler)
      subscription_groups.stubs(:[]).with(sg_id).returns({})

      subscription_groups.expects(:[]).with(sg_id).returns({})

      listener.on_connection_listener_before_fetch_loop(event)
    end

    it "accesses subscription group by id in the track block" do
      sampler.stubs(:track).yields(sampler)
      subscription_groups.stubs(:[]).with(sg_id).returns({})

      listener.on_connection_listener_before_fetch_loop(event)
    end

    context "when group.instance.id is configured" do
      before do
        subscription_group.stubs(:kafka).returns({ "group.instance.id": "my-static-instance" })

        sampler.stubs(:track).yields(sampler)

        subscription_groups[sg_id] = {}
      end

      it "stores the instance_id in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        assert_equal("my-static-instance", subscription_groups[sg_id][:instance_id])
      end
    end

    context "when group.instance.id is not configured" do
      before do
        subscription_group.stubs(:kafka).returns({})
        sampler.stubs(:track).yields(sampler)
        subscription_groups[sg_id] = {}
      end

      it "stores false for instance_id in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        refute(subscription_groups[sg_id][:instance_id])
      end
    end

    context "when max.poll.interval.ms is configured" do
      before do
        subscription_group.stubs(:kafka).returns({ "max.poll.interval.ms": 600_000 })

        sampler.stubs(:track).yields(sampler)

        subscription_groups[sg_id] = {}
      end

      it "stores the poll_interval in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        assert_equal(600_000, subscription_groups[sg_id][:poll_interval])
      end
    end

    context "when max.poll.interval.ms is not configured" do
      before do
        subscription_group.stubs(:kafka).returns({})
        sampler.stubs(:track).yields(sampler)
        subscription_groups[sg_id] = {}
      end

      it "stores the default poll_interval (300000ms) in subscription group data" do
        listener.on_connection_listener_before_fetch_loop(event)

        assert_equal(300_000, subscription_groups[sg_id][:poll_interval])
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
      sampler.stubs(:track).yields(sampler)

      sampler.expects(:track).yields(sampler)
      listener.on_connection_listener_after_fetch_loop(event)

      # Verify the deletions happened
      refute(consumer_groups[cg_id][:subscription_groups].key?(sg_id))
      refute(subscription_groups.key?(sg_id))
    end

    it "cleans up subscription group data properly" do
      sampler.stubs(:track).yields(sampler)

      consumer_groups[cg_id][:subscription_groups].expects(:delete).with(sg_id)
      subscription_groups.expects(:delete).with(sg_id)

      listener.on_connection_listener_after_fetch_loop(event)
    end

    context "when subscription group is not present" do
      before do
        consumer_groups[cg_id][:subscription_groups].clear
        subscription_groups.clear
      end

      it "handles missing subscription group gracefully" do
        sampler.stubs(:track).yields(sampler)

        sampler.expects(:track).yields(sampler)
        listener.on_connection_listener_after_fetch_loop(event)
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
      sampler.stubs(:track).yields(sampler)

      listener.on_connection_listener_fetch_loop_received(event)

      assert_kind_of(Float, subscription_groups[sg_id][:polled_at])
    end

    it "uses monotonic time for polled_at timestamp" do
      stub_and_passthrough(listener, :monotonic_now)
      sampler.stubs(:track).yields(sampler)

      listener.on_connection_listener_fetch_loop_received(event)
    end

    it "updates existing subscription group data" do
      subscription_groups[sg_id][:existing_data] = "preserved"
      sampler.stubs(:track).yields(sampler)

      listener.on_connection_listener_fetch_loop_received(event)

      assert_equal("preserved", subscription_groups[sg_id][:existing_data])
      assert_kind_of(Float, subscription_groups[sg_id][:polled_at])
    end

    context "when subscription group does not exist" do
      before do
        subscription_groups.delete(sg_id)
      end

      it "creates the subscription group entry" do
        sampler.stubs(:track).yields(sampler)
        subscription_groups.stubs(:[]).with(sg_id).returns({})

        listener.on_connection_listener_fetch_loop_received(event)
      end
    end
  end

  describe "inheritance from Base" do
    it "inherits from Base listener" do
      assert_equal(Karafka::Web::Tracking::Consumers::Listeners::Base, described_class.superclass)
    end

    it "has access to base class methods" do
      assert_respond_to(listener, :track)
      assert_respond_to(listener, :report)
      assert_respond_to(listener, :report!)
    end

    it "has access to time helper methods from base" do
      assert_respond_to(listener, :monotonic_now)
      assert_respond_to(listener, :float_now)
    end
  end

  describe "integration scenarios" do
    let(:event_before) { { subscription_group: subscription_group } }
    let(:event_received) { { subscription_group: subscription_group } }
    let(:event_after) { { subscription_group: subscription_group } }

    before do
      # Setup proper tracking calls
      sampler.stubs(:track).yields(sampler)
      subscription_groups[sg_id] = {}
      consumer_groups[cg_id][:subscription_groups][sg_id] = {}
    end

    it "handles complete fetch loop lifecycle" do
      # Before fetch loop - initialize
      listener.on_connection_listener_before_fetch_loop(event_before)

      # During fetch loop - update polled_at
      listener.on_connection_listener_fetch_loop_received(event_received)

      assert_kind_of(Float, subscription_groups[sg_id][:polled_at])

      # After fetch loop - cleanup
      listener.on_connection_listener_after_fetch_loop(event_after)

      refute(subscription_groups.key?(sg_id))
      refute(consumer_groups[cg_id][:subscription_groups].key?(sg_id))
    end

    it "handles multiple polling events during fetch loop" do
      listener.on_connection_listener_before_fetch_loop(event_before)

      first_time = listener.monotonic_now
      listener.stubs(:monotonic_now).returns(first_time)
      listener.on_connection_listener_fetch_loop_received(event_received)

      second_time = first_time + 1.0
      listener.stubs(:monotonic_now).returns(second_time)
      listener.on_connection_listener_fetch_loop_received(event_received)

      assert_equal(second_time, subscription_groups[sg_id][:polled_at])
    end
  end

  describe "error handling" do
    let(:event) { { subscription_group: subscription_group } }

    context "when sampler tracking fails" do
      before do
        sampler.stubs(:track).raises(StandardError, "Sampler error")
      end

      it "allows errors to propagate from before_fetch_loop" do
        e = assert_raises(StandardError) { listener.on_connection_listener_before_fetch_loop(event) }
        assert_includes(e.message, "Sampler error")
      end

      it "allows errors to propagate from after_fetch_loop" do
        e = assert_raises(StandardError) { listener.on_connection_listener_after_fetch_loop(event) }
        assert_includes(e.message, "Sampler error")
      end

      it "allows errors to propagate from fetch_loop_received" do
        e = assert_raises(StandardError) { listener.on_connection_listener_fetch_loop_received(event) }
        assert_includes(e.message, "Sampler error")
      end
    end
  end
end
