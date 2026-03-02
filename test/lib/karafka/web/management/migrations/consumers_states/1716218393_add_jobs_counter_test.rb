# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersStates::AddJobsCounter
) do
  it { assert_equal("1.4.0", described_class.versions_until) }
  it { assert_equal(:consumers_states, described_class.type) }

  context "when migrating from 1.3.1" do
    let(:state) { Fixtures.consumers_states_json("v1.4.0") }

    before { described_class.new.migrate(state) }

    it { assert_equal(16_351, state[:stats][:jobs]) }
    it { assert_equal(true, state[:stats].key?(:jobs)) }
  end
end
