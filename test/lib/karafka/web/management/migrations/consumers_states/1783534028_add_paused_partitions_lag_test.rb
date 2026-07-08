# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersStates::AddPausedPartitionsLag
) do
  it { assert_equal("1.5.0", described_class.versions_until) }
  it { assert_equal(:consumers_states, described_class.type) }

  context "when migrating from 1.4.0" do
    let(:state) { Fixtures.consumers_states_json("v1.4.0") }

    before { described_class.new.migrate(state) }

    it { assert_equal({}, state[:paused_partitions_lag]) }
    it { assert(state.key?(:paused_partitions_lag)) }
  end
end
