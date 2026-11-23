# frozen_string_literal: true

describe_current do
  let(:migration) { described_class.new }

  let(:subscription_group) do
    {
      id: "sg_0",
      instance_id: false,
      state: {
        state: "up",
        join_state: "steady",
        stateage: 1000,
        rebalance_age: 1000,
        rebalance_cnt: 1,
        rebalance_reason: "test",
        poll_age: 100,
        poll_interval: 300_000
      },
      topics: {}
    }
  end

  let(:report) do
    {
      schema_version: "1.7.0",
      consumer_groups: {
        "test_group" => {
          id: "test_group",
          subscription_groups: { "sg_0" => subscription_group }
        }
      },
      dispatched_at: Time.now.to_f
    }
  end

  let(:migrated_sg) { report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"] }

  describe ".applicable?" do
    it { assert(described_class.applicable?("1.7.0")) }
    it { assert(described_class.applicable?("1.6.0")) }
    it { assert(described_class.applicable?("1.0.0")) }
    it { refute(described_class.applicable?("1.8.0")) }
    it { refute(described_class.applicable?("2.0.0")) }
  end

  describe "#migrate" do
    context "when subscription groups do not have member_id" do
      before { migration.migrate(report) }

      it "adds member_id with false value to subscription group" do
        assert(migrated_sg.key?(:member_id))
        refute(migrated_sg[:member_id])
      end

      it "preserves other subscription group fields" do
        assert_equal("sg_0", migrated_sg[:id])
        refute(migrated_sg[:instance_id])
        assert_equal("up", migrated_sg[:state][:state])
        assert_equal(300_000, migrated_sg[:state][:poll_interval])
      end
    end

    context "when subscription group already has member_id" do
      before do
        subscription_group[:member_id] = "rdkafka-member-1"
        migration.migrate(report)
      end

      it { assert_equal("rdkafka-member-1", migrated_sg[:member_id]) }
    end

    context "when there are multiple consumer and subscription groups" do
      before do
        report[:consumer_groups]["test_group"][:subscription_groups]["sg_1"] = { id: "sg_1" }
        report[:consumer_groups]["other_group"] = {
          id: "other_group",
          subscription_groups: { "sg_2" => { id: "sg_2" } }
        }

        migration.migrate(report)
      end

      it "adds member_id to all of them" do
        report[:consumer_groups].each_value do |cg|
          cg[:subscription_groups].each_value do |sg|
            assert(sg.key?(:member_id))
            refute(sg[:member_id])
          end
        end
      end
    end

    context "when report has no consumer groups" do
      let(:report) { { schema_version: "1.7.0", dispatched_at: Time.now.to_f } }

      it { migration.migrate(report) }
    end

    context "when a consumer group has no subscription groups" do
      let(:report) do
        {
          schema_version: "1.7.0",
          consumer_groups: { "test_group" => { id: "test_group" } },
          dispatched_at: Time.now.to_f
        }
      end

      it { migration.migrate(report) }
    end
  end
end
