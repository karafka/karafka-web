# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::RemoveProcessingFromConsumersState do
  it { expect(described_class.versions_until).to eq('1.2.1') }
  it { expect(described_class.type).to eq(:consumers_state) }

  pending
end
