# frozen_string_literal: true

RSpec.describe_current do
  subject(:policy) { described_class.new }

  describe '#allow?' do
    it { expect(policy.allow?({})).to eq(true) }
  end
end
