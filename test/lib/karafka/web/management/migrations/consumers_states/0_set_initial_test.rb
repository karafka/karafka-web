# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersStates::SetInitial
) do
  it { assert_equal("0.0.1", described_class.versions_until) }
  it { assert_equal(:consumers_states, described_class.type) }

  # This migration is covered in the migrator specs for initial setup
end
