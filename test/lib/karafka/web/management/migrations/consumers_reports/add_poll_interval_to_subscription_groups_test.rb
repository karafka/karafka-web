# frozen_string_literal: true

describe_current do
  let(:migration) { described_class.new }

  describe ".applicable?" do
    context "when schema version is less than 1.7.0" do
      it "returns true for 1.6.0" do
        assert(described_class.applicable?("1.6.0"))
      end

      it "returns true for 1.5.0" do
        assert(described_class.applicable?("1.5.0"))
      end

      it "returns true for 1.0.0" do
        assert(described_class.applicable?("1.0.0"))
      end
    end

    context "when schema version is 1.7.0 or higher" do
      it "returns false for 1.7.0" do
        refute(described_class.applicable?("1.7.0"))
      end

      it "returns false for 1.8.0" do
        refute(described_class.applicable?("1.8.0"))
      end

      it "returns false for 2.0.0" do
        refute(described_class.applicable?("2.0.0"))
      end
    end
  end

  describe "#migrate" do
    context "when subscription groups do not have poll_interval" do
      let(:report) do
        {
          schema_version: "1.6.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  instance_id: false,
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

      it "adds poll_interval with default value (300000ms) to subscription group state" do
        migration.migrate(report)

        state = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"][:state]

        assert_equal(300_000, state[:poll_interval])
      end

      it "preserves other state fields" do
        migration.migrate(report)

        state = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"][:state]

        assert_equal("up", state[:state])
        assert_equal("steady", state[:join_state])
        assert_equal(100, state[:poll_age])
      end
    end

    context "when subscription groups already have poll_interval" do
      let(:report) do
        {
          schema_version: "1.7.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  instance_id: false,
                  state: {
                    state: "up",
                    join_state: "steady",
                    poll_interval: 600_000
                  },
                  topics: {}
                }
              }
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "does not modify existing poll_interval" do
        migration.migrate(report)

        state = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"][:state]

        assert_equal(600_000, state[:poll_interval])
      end
    end

    context "when there are multiple subscription groups" do
      let(:report) do
        {
          schema_version: "1.6.0",
          consumer_groups: {
            "cg_1" => {
              id: "cg_1",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  instance_id: false,
                  state: { state: "up", join_state: "steady", poll_age: 50 },
                  topics: {}
                },
                "sg_1" => {
                  id: "sg_1",
                  instance_id: false,
                  state: { state: "up", join_state: "steady", poll_age: 60 },
                  topics: {}
                }
              }
            },
            "cg_2" => {
              id: "cg_2",
              subscription_groups: {
                "sg_2" => {
                  id: "sg_2",
                  instance_id: false,
                  state: { state: "up", join_state: "steady", poll_age: 70 },
                  topics: {}
                }
              }
            }
          },
          dispatched_at: Time.now.to_f
        }
      end

      it "adds poll_interval to all subscription groups" do
        migration.migrate(report)

        cg1_sgs = report[:consumer_groups]["cg_1"][:subscription_groups]
        cg2_sgs = report[:consumer_groups]["cg_2"][:subscription_groups]

        assert_equal(300_000, cg1_sgs["sg_0"][:state][:poll_interval])
        assert_equal(300_000, cg1_sgs["sg_1"][:state][:poll_interval])
        assert_equal(300_000, cg2_sgs["sg_2"][:state][:poll_interval])
      end
    end

    context "when consumer_groups is nil" do
      let(:report) do
        {
          schema_version: "1.6.0",
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
          schema_version: "1.6.0",
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

    context "when state is nil" do
      let(:report) do
        {
          schema_version: "1.6.0",
          consumer_groups: {
            "test_group" => {
              id: "test_group",
              subscription_groups: {
                "sg_0" => {
                  id: "sg_0",
                  instance_id: false,
                  state: nil,
                  topics: {}
                }
              }
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
