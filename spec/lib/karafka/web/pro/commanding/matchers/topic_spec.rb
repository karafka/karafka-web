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

  let(:matchers) { { topic: 'my_topic' } }

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
    context 'when topic is not specified in matchers' do
      let(:matchers) { {} }

      it { expect(matcher.apply?).to be false }
    end

    context 'when topic is specified in matchers' do
      let(:matchers) { { topic: 'my_topic' } }

      it { expect(matcher.apply?).to be true }
    end
  end

  describe '#matches?' do
    context 'when topic name matches an assigned topic' do
      let(:matchers) { { topic: 'my_topic' } }

      it { expect(matcher.matches?).to be true }
    end

    context 'when topic name does not match any assigned topic' do
      let(:matchers) { { topic: 'other_topic' } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are no assignments' do
      let(:assignments) { {} }
      let(:matchers) { { topic: 'my_topic' } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are multiple topic assignments' do
      let(:topic2) do
        instance_double(
          Karafka::Routing::Topic,
          name: 'second_topic',
          consumer_group: consumer_group
        )
      end

      let(:assignments) { { topic => [0, 1], topic2 => [0] } }

      context 'when matching first topic' do
        let(:matchers) { { topic: 'my_topic' } }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching second topic' do
        let(:matchers) { { topic: 'second_topic' } }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching neither topic' do
        let(:matchers) { { topic: 'third_topic' } }

        it { expect(matcher.matches?).to be false }
      end
    end
  end
end
