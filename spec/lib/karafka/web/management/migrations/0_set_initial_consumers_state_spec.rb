# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::SetInitialConsumersState do
  it { expect(described_class.versions_until).to eq('0.0.1') }
  it { expect(described_class.type).to eq(:consumers_state) }

  # This migration is covered in the migrator specs for initial setup
end
