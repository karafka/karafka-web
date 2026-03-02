# frozen_string_literal: true

describe_current do
  let(:sampler) { described_class.new }

  describe "#track" do
    before { sampler.track { |sam| sam.errors << 1 } }

    it { assert_equal([1], sampler.errors) }
  end

  describe "#clear" do
    before do
      sampler.track { |sam| sam.errors << 1 }
      sampler.clear
    end

    it { assert_equal([], sampler.errors) }
  end
end
