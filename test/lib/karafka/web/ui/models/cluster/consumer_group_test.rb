# frozen_string_literal: true

describe_current do
  let(:model) { described_class }

  let(:topic) { create_topic(partitions: 2) }
  let(:other_topic) { create_topic }
  let(:group_id) { SecureRandom.uuid }
  let(:not_found_error) { Karafka::Web::Errors::Ui::NotFoundError }

  before do
    other_topic
    produce_many(topic, Array.new(10) { |i| i.to_s }, partition: 1)
    Karafka::Admin.seek_consumer_group(group_id, { topic => { 1 => 4 } })
  end

  describe ".all" do
    let(:group) { model.all.find { |consumer_group| consumer_group.id == group_id } }

    it "lists the consumer group that only has committed offsets" do
      refute_nil(group)
      assert_equal(:empty, group[:state])
    end

    it { assert_equal(model.all.map(&:id).sort, model.all.map(&:id)) }
  end

  describe ".find" do
    context "when the consumer group does not exist" do
      it { assert_raises(not_found_error) { model.find(SecureRandom.uuid) } }
    end

    context "when the consumer group exists" do
      let(:group) { model.find(group_id) }

      it "describes it" do
        assert_equal(group_id, group.id)
        assert_equal(:empty, group[:state])
        assert_empty(group.members)
      end
    end
  end

  describe "#offsets" do
    let(:offsets) { model.find(group_id).offsets }

    it "returns offsets and lags of all the partitions of the topics with committed offsets" do
      assert_equal(
        [
          { topic_name: topic, id: 0, lag: -1, stored_offset: -1 },
          { topic_name: topic, id: 1, lag: 6, stored_offset: 4 }
        ],
        offsets
      )
    end

    context "when the consumer group has offsets on topics that do not come sorted" do
      before do
        Karafka::Admin
          .stubs(:read_lags_with_offsets)
          .returns(
            group_id => {
              "b-topic" => { 0 => { offset: 1, lag: 0 } },
              "a-topic" => {
                1 => { offset: 2, lag: 0 },
                0 => { offset: 3, lag: 0 }
              }
            }
          )
      end

      it "orders them by topic name and partition" do
        assert_equal(
          [%w[a-topic 0], %w[a-topic 1], %w[b-topic 0]],
          offsets.map { |partition| [partition[:topic_name], partition[:id].to_s] }
        )
      end
    end

    context "when no partition of a topic has a committed offset" do
      before do
        Karafka::Admin
          .stubs(:read_lags_with_offsets)
          .returns(
            group_id => {
              "a-topic" => { 0 => { offset: -1, lag: -1 } },
              "b-topic" => { 0 => { offset: 1, lag: 0 } }
            }
          )
      end

      it { assert_equal(%w[b-topic], offsets.map { |partition| partition[:topic_name] }) }
    end
  end
end
