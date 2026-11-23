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

  describe "#target_assignments?" do
    let(:group) { model.new(group_id: group_id, members: members) }
    let(:member) { { member_id: "m1", assignment: { topic => [0] }, target_assignment: nil } }

    context "when the group has no members" do
      let(:members) { [] }

      it { refute_predicate(group, :target_assignments?) }
    end

    context "when no member has a target assignment (classic group)" do
      let(:members) { [member] }

      it { refute_predicate(group, :target_assignments?) }
    end

    context "when a member has a target assignment (consumer group)" do
      let(:members) { [member, member.merge(target_assignment: { topic => [1] })] }

      it { assert_predicate(group, :target_assignments?) }
    end
  end

  describe "#topics" do
    let(:topics) { model.find(group_id).topics }

    it "returns only the topics with committed offsets" do
      assert_equal([topic], topics.keys)
    end

    it "returns offsets and lags of all the partitions of the topic" do
      assert_equal(
        [
          { id: 0, lag: -1, stored_offset: -1 },
          { id: 1, lag: 6, stored_offset: 4 }
        ],
        topics.fetch(topic).sort_by { |partition| partition[:id] }
      )
    end

    context "when the consumer group has offsets on topics that do not come sorted" do
      before do
        Karafka::Admin
          .stubs(:read_lags_with_offsets)
          .returns(
            group_id => {
              "b-topic" => { 0 => { offset: 1, lag: 0 } },
              "a-topic" => { 0 => { offset: 2, lag: 0 } }
            }
          )
      end

      it { assert_equal(%w[a-topic b-topic], topics.keys) }
    end
  end
end
