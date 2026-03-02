# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersStates::IntroduceLagTotal
) do
  it { assert_equal("1.3.0", described_class.versions_until) }
  it { assert_equal(:consumers_states, described_class.type) }

  context "when migrating from 1.1.0" do
    let(:state) { Fixtures.consumers_states_json("v1.1.0") }

    before { described_class.new.migrate(state) }

    it { assert_equal(0, state[:stats][:lag_total]) }
    it { assert_equal(false, state[:stats].key?(:lag)) }
    it { assert_equal(false, state[:stats].key?(:lag_stored)) }
  end

  context "when migrating from 1.2.2" do
    let(:state) { Fixtures.consumers_states_json("v1.2.2") }

    before { described_class.new.migrate(state) }

    it { assert_equal(0, state[:stats][:lag_total]) }
    it { assert_equal(false, state[:stats].key?(:lag)) }
    it { assert_equal(false, state[:stats].key?(:lag_stored)) }
  end
end
