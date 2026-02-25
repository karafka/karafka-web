# frozen_string_literal: true

RSpec.describe_current do
  subject(:migration) { described_class.new }

  describe ".applicable?" do
    context "when schema version is less than 1.7.0" do
      it "returns true for 1.6.0" do
        expect(described_class.applicable?("1.6.0")).to be true
      end

      it "returns true for 1.5.0" do
        expect(described_class.applicable?("1.5.0")).to be true
      end

      it "returns true for 1.0.0" do
        expect(described_class.applicable?("1.0.0")).to be true
      end
    end

    context "when schema version is 1.7.0 or higher" do
      it "returns false for 1.7.0" do
        expect(described_class.applicable?("1.7.0")).to be false
      end

      it "returns false for 1.8.0" do
        expect(described_class.applicable?("1.8.0")).to be false
      end

      it "returns false for 2.0.0" do
        expect(described_class.applicable?("2.0.0")).to be false
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
        expect(state[:poll_interval]).to eq(300_000)
      end

      it "preserves other state fields" do
        migration.migrate(report)

        state = report[:consumer_groups]["test_group"][:subscription_groups]["sg_0"][:state]
        expect(state[:state]).to eq("up")
        expect(state[:join_state]).to eq("steady")
        expect(state[:poll_age]).to eq(100)
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
        expect(state[:poll_interval]).to eq(600_000)
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
        expect(cg1_sgs["sg_0"][:state][:poll_interval]).to eq(300_000)
        expect(cg1_sgs["sg_1"][:state][:poll_interval]).to eq(300_000)
        expect(cg2_sgs["sg_2"][:state][:poll_interval]).to eq(300_000)
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
        expect { migration.migrate(report) }.not_to raise_error
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
        expect { migration.migrate(report) }.not_to raise_error
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
        expect { migration.migrate(report) }.not_to raise_error
      end
    end
  end
end
