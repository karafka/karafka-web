# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:subscription_group) { instance_double(Karafka::Routing::SubscriptionGroup) }
  let(:process_tags) { instance_double(Karafka::Core::Taggable::Tags) }
  let(:kafka_config) { {} }
  let(:sg_id) { 'test_group_sg_0' }

  let(:event) do
    { subscription_group: subscription_group }
  end

  before do
    allow(subscription_group).to receive_messages(kafka: kafka_config, id: sg_id)
    allow(Karafka::Process).to receive(:tags).and_return(process_tags)
    allow(process_tags).to receive(:add)
  end

  describe '#on_connection_listener_before_fetch_loop' do
    context 'when group.instance.id is configured' do
      let(:kafka_config) { { 'group.instance.id': 'my-static-instance-1' } }

      it 'adds the group instance id as a process tag with subscription group id in the key' do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(process_tags).to have_received(:add).with(:"gid_#{sg_id}", 'gid:my-static-instance-1')
      end

      context 'with a different instance id' do
        let(:kafka_config) { { 'group.instance.id': 'worker-node-42' } }

        it 'adds the different instance id as a process tag' do
          listener.on_connection_listener_before_fetch_loop(event)

          expect(process_tags).to have_received(:add).with(:"gid_#{sg_id}", 'gid:worker-node-42')
        end
      end
    end

    context 'when group.instance.id is not configured' do
      let(:kafka_config) { { 'group.id': 'my-group' } }

      it 'does not add a group instance id tag' do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(process_tags).not_to have_received(:add)
      end
    end

    context 'when group.instance.id is nil' do
      let(:kafka_config) { { 'group.instance.id': nil } }

      it 'does not add a group instance id tag' do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(process_tags).not_to have_received(:add)
      end
    end

    context 'when kafka config is empty' do
      let(:kafka_config) { {} }

      it 'does not add a group instance id tag' do
        listener.on_connection_listener_before_fetch_loop(event)

        expect(process_tags).not_to have_received(:add)
      end
    end
  end

  describe 'multiplexing scenarios' do
    context 'when multiple subscription groups have different group.instance.ids' do
      let(:subscription_group1) { instance_double(Karafka::Routing::SubscriptionGroup) }
      let(:subscription_group2) { instance_double(Karafka::Routing::SubscriptionGroup) }
      let(:sg_id1) { 'consumer_group_sg_0' }
      let(:sg_id2) { 'consumer_group_sg_1' }
      let(:kafka_config1) { { 'group.instance.id': 'instance-1' } }
      let(:kafka_config2) { { 'group.instance.id': 'instance-2' } }

      let(:event1) { { subscription_group: subscription_group1 } }
      let(:event2) { { subscription_group: subscription_group2 } }

      before do
        allow(subscription_group1).to receive_messages(kafka: kafka_config1, id: sg_id1)
        allow(subscription_group2).to receive_messages(kafka: kafka_config2, id: sg_id2)
      end

      it 'adds tags for each subscription group with unique keys' do
        listener.on_connection_listener_before_fetch_loop(event1)
        listener.on_connection_listener_before_fetch_loop(event2)

        expect(process_tags).to have_received(:add).with(:"gid_#{sg_id1}", 'gid:instance-1')
        expect(process_tags).to have_received(:add).with(:"gid_#{sg_id2}", 'gid:instance-2')
      end

      it 'does not overwrite tags because each subscription group has a unique key' do
        listener.on_connection_listener_before_fetch_loop(event1)
        listener.on_connection_listener_before_fetch_loop(event2)

        # Each call uses a different key, so no overwriting occurs
        expect(process_tags).to have_received(:add).twice
      end
    end

    context 'when only some subscription groups have group.instance.id' do
      let(:subscription_group1) { instance_double(Karafka::Routing::SubscriptionGroup) }
      let(:subscription_group2) { instance_double(Karafka::Routing::SubscriptionGroup) }
      let(:sg_id1) { 'consumer_group_sg_0' }
      let(:sg_id2) { 'consumer_group_sg_1' }
      let(:kafka_config1) { { 'group.instance.id': 'instance-1' } }
      let(:kafka_config2) { { 'group.id': 'my-group' } }

      let(:event1) { { subscription_group: subscription_group1 } }
      let(:event2) { { subscription_group: subscription_group2 } }

      before do
        allow(subscription_group1).to receive_messages(kafka: kafka_config1, id: sg_id1)
        allow(subscription_group2).to receive_messages(kafka: kafka_config2, id: sg_id2)
      end

      it 'only adds tags for subscription groups with group.instance.id' do
        listener.on_connection_listener_before_fetch_loop(event1)
        listener.on_connection_listener_before_fetch_loop(event2)

        expect(process_tags).to have_received(:add).with(:"gid_#{sg_id1}", 'gid:instance-1').once
        expect(process_tags).to have_received(:add).once
      end
    end

    context 'when subscription groups are stopped (downscaling)' do
      let(:kafka_config) { { 'group.instance.id': 'instance-1' } }

      it 'does not remove tags when subscription groups stop (tags are kept for debugging)' do
        # Tags are intentionally not removed when subscription groups stop
        # because the historical association is valuable for debugging
        listener.on_connection_listener_before_fetch_loop(event)

        expect(process_tags).to have_received(:add).with(:"gid_#{sg_id}", 'gid:instance-1')
        # No on_connection_listener_after_fetch_loop handler exists - tags persist
        expect(listener).not_to respond_to(:on_connection_listener_after_fetch_loop)
      end
    end
  end

  describe 'inheritance from Base' do
    it 'inherits from Base listener' do
      expect(described_class.superclass).to eq(Karafka::Web::Tracking::Consumers::Listeners::Base)
    end
  end
end
