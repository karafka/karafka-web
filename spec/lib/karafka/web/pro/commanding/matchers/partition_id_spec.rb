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
  let(:matchers) { { partition_id: 0 } }
  let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup, id: 'my_consumer_group') }
  let(:topic) { instance_double(Karafka::Routing::Topic, name: 'my_topic', consumer_group: consumer_group) }
  let(:assignments) { { topic => [0, 1, 2] } }

  before do
    allow(Karafka::App).to receive(:assignments).and_return(assignments)
  end

  describe '#apply?' do
    context 'when partition_id is not specified in matchers' do
      let(:matchers) { {} }

      it { expect(matcher.apply?).to be false }
    end

    context 'when partition_id is specified in matchers' do
      let(:matchers) { { partition_id: 0 } }

      it { expect(matcher.apply?).to be true }
    end
  end

  describe '#matches?' do
    context 'when partition_id matches an assigned partition' do
      let(:matchers) { { partition_id: 0 } }

      it { expect(matcher.matches?).to be true }
    end

    context 'when partition_id does not match any assigned partition' do
      let(:matchers) { { partition_id: 99 } }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are no assignments' do
      let(:assignments) { {} }
      let(:matchers) { { partition_id: 0 } }

      it { expect(matcher.matches?).to be false }
    end

    context 'with multiple topics' do
      let(:topic2) do
        instance_double(Karafka::Routing::Topic, name: 'other_topic', consumer_group: consumer_group)
      end
      let(:assignments) { { topic => [0, 1], topic2 => [5, 6] } }

      context 'when partition exists in any topic' do
        let(:matchers) { { partition_id: 5 } }

        it { expect(matcher.matches?).to be true }
      end

      context 'when partition does not exist in any topic' do
        let(:matchers) { { partition_id: 99 } }

        it { expect(matcher.matches?).to be false }
      end

      context 'when partition exists in first topic' do
        let(:matchers) { { partition_id: 0 } }

        it { expect(matcher.matches?).to be true }
      end
    end
  end
end
