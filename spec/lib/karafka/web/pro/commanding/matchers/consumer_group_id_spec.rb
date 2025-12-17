# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(message) }

  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { matchers: matchers }
    )
  end

  let(:matchers) { { consumer_group_id: 'my_consumer_group' } }

  let(:consumer_group) do
    instance_double(Karafka::Routing::ConsumerGroup, id: 'my_consumer_group')
  end

  let(:topic) do
    instance_double(Karafka::Routing::Topic, name: 'my_topic', consumer_group: consumer_group)
  end

  let(:assignments) { { topic => [0, 1, 2] } }

  before do
    allow(Karafka::App).to receive(:assignments).and_return(assignments)
  end

  describe '#apply?' do
    context 'when consumer_group_id is not specified in matchers' do
      let(:matchers) { {} }

      it { expect(matcher.apply?).to be false }
    end

    context 'when consumer_group_id is specified in matchers' do
      let(:matchers) { { consumer_group_id: 'my_consumer_group' } }

      it { expect(matcher.apply?).to be true }
    end
  end

  describe '#matches?' do
    context 'when consumer_group_id matches an assigned topic consumer group' do
      let(:matchers) { { consumer_group_id: 'my_consumer_group' } }

      it { expect(matcher.matches?).to be true }
    end

    context 'when consumer_group_id does not match any assigned consumer group' do
      let(:matchers) { { consumer_group_id: 'other_consumer_group' } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are no assignments' do
      let(:assignments) { {} }
      let(:matchers) { { consumer_group_id: 'my_consumer_group' } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are multiple assignments from different consumer groups' do
      let(:consumer_group2) do
        instance_double(Karafka::Routing::ConsumerGroup, id: 'second_consumer_group')
      end

      let(:topic2) do
        instance_double(Karafka::Routing::Topic, name: 'topic2', consumer_group: consumer_group2)
      end

      let(:assignments) { { topic => [0, 1], topic2 => [0] } }

      context 'when matching first consumer group' do
        let(:matchers) { { consumer_group_id: 'my_consumer_group' } }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching second consumer group' do
        let(:matchers) { { consumer_group_id: 'second_consumer_group' } }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching neither consumer group' do
        let(:matchers) { { consumer_group_id: 'third_consumer_group' } }

        it { expect(matcher.matches?).to be false }
      end
    end
  end
end
