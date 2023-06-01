# frozen_string_literal: true

RSpec.describe_current do
  subject(:sampler) { described_class.new }

  describe '#track' do
    before { sampler.track { |sam| sam.errors << 1 } }

    it { expect(sampler.errors).to eq([1]) }
  end

  describe '#clear' do
    before do
      sampler.track { |sam| sam.errors << 1 }
      sampler.clear
    end

    it { expect(sampler.errors).to eq([]) }
  end
end
