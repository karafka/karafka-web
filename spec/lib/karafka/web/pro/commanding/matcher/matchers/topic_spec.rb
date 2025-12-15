# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(topic_name) }

  let(:topic_name) { 'my_topic' }
  let(:consumer_group) { instance_double(Karafka::Routing::ConsumerGroup, id: 'my_consumer_group') }
  let(:topic) { instance_double(Karafka::Routing::Topic, name: 'my_topic', consumer_group: consumer_group) }
  let(:assignments) { { topic => [0, 1, 2] } }

  before do
    allow(Karafka::App).to receive(:assignments).and_return(assignments)
  end

  describe '#matches?' do
    context 'when topic name matches an assigned topic' do
      let(:topic_name) { 'my_topic' }

      it { expect(matcher.matches?).to be true }
    end

    context 'when topic name does not match any assigned topic' do
      let(:topic_name) { 'other_topic' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are no assignments' do
      let(:assignments) { {} }
      let(:topic_name) { 'my_topic' }

      it { expect(matcher.matches?).to be false }
    end

    context 'when there are multiple topic assignments' do
      let(:topic2) { instance_double(Karafka::Routing::Topic, name: 'second_topic', consumer_group: consumer_group) }
      let(:assignments) { { topic => [0, 1], topic2 => [0] } }

      context 'when matching first topic' do
        let(:topic_name) { 'my_topic' }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching second topic' do
        let(:topic_name) { 'second_topic' }

        it { expect(matcher.matches?).to be true }
      end

      context 'when matching neither topic' do
        let(:topic_name) { 'third_topic' }

        it { expect(matcher.matches?).to be false }
      end
    end
  end
end
