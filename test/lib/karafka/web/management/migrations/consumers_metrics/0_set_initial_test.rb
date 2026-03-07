# frozen_string_literal: true

describe(
  Karafka::Web::Management::Migrations::ConsumersMetrics::SetInitial
) do
  it { assert_equal("0.0.1", described_class.versions_until) }
  it { assert_equal(:consumers_metrics, described_class.type) }

  # This migration is covered in the migrator specs for initial setup
end
