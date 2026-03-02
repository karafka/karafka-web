# frozen_string_literal: true

describe_current do
  let(:migration) { described_class.new }

  describe ".applicable?" do
    context "when schema version is less than 1.6.0" do
      it "returns true for 1.5.0" do
        assert_equal(true, described_class.applicable?("1.5.0"))
      end

      it "returns true for 1.4.0" do
        assert_equal(true, described_class.applicable?("1.4.0"))
      end

      it "returns true for 1.0.0" do
        assert_equal(true, described_class.applicable?("1.0.0"))
      end
    end

    context "when schema version is 1.6.0 or higher" do
      it "returns false for 1.6.0" do
        assert_equal(false, described_class.applicable?("1.6.0"))
      end

      it "returns false for 1.7.0" do
        assert_equal(false, described_class.applicable?("1.7.0"))
      end

      it "returns false for 2.0.0" do
        assert_equal(false, described_class.applicable?("2.0.0"))
      end
    end
  end

  describe "#migrate" do
    context "when subscription groups do not have instance_id" do
      let(:report) do
        {
          schema_version: "1.5.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  state: {
                    state: "up",
                    join_state: "steady",
                    stateage: 1000,
                    rebalance_age: 1000,
                    rebalance_cnt: 1,
                    rebalance_reason: "test",
                    poll_age: 100
                  },
                  topics: {}
                }
              }
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "adds instance_id with false value to subscription group" do
        migration.migrate(report)

        sg = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"]
        assert_equal(false, sg[:instance_id])
      end

      it "preserves other subscription group fields" do
        migration.migrate(report)

        sg = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"]
        assert_equal("sg_0", sg[:id])
        assert_equal("up", sg[:state][:state])
        assert_equal("steady", sg[:state][:join_state])
      end
    end

    context "when subscription groups already have instance_id" do
      let(:report) do
        {
          schema_version: "1.6.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  instance_id: "my-static-instance",
                  state: {
                    state: "up",
                    join_state: "steady"
                  },
                  topics: {}
                }
              }
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "does not modify existing instance_id" do
        migration.migrate(report)

        group = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"]
        instance_id = group[:instance_id]

        assert_equal("my-static-instance", instance_id)
      end
    end

    context "when there are multiple subscription groups" do
      let(:report) do
        {
          schema_version: "1.5.0",
          consumer_groups: {
            "cg_1" => {
              id: "cg_1",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  state: { state: "up", join_state: "steady" },
                  topics: {}
                },
                "sg_1" => {
                  id: "sg_1",
                  state: { state: "up", join_state: "steady" },
                  topics: {}
                }
              }
            },
            "cg_2" => {
              id: "cg_2",
              subscription_groups: {
                "sg_2" => {
                  id: "sg_2",
                  state: { state: "up", join_state: "steady" },
                  topics: {}
                }
              }
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "adds instance_id to all subscription groups" do
        migration.migrate(report)

        cg1_sgs = report[:consumer_groups]["cg_1"][:subscription_groups]
        cg2_sgs = report[:consumer_groups]["cg_2"][:subscription_groups]
        assert_equal(false, cg1_sgs["sg_0"][:instance_id])
        assert_equal(false, cg1_sgs["sg_1"][:instance_id])
        assert_equal(false, cg2_sgs["sg_2"][:instance_id])
      end
    end

    context "when consumer_groups is nil" do
      let(:report) do
        {
          schema_version: "1.5.0",
          consumer_groups: nil,
          dispatched_at: Time.now.to_f
        }
      end

      it "does not raise an error" do
        migration.migrate(report)
      end
    end

    context "when subscription_groups is nil" do
      let(:report) do
        {
          schema_version: "1.5.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: nil
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "does not raise an error" do
        migration.migrate(report)
      end
    end
  end
end
