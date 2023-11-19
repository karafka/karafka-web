# frozen_string_literal: true

RSpec.describe Karafka::Web::Management::Migrations::RemoveProcessingFromConsumersMetrics do
  it { expect(described_class.versions_until).to eq('1.1.1') }
  it { expect(described_class.type).to eq(:consumers_metrics) }

  pending
end
