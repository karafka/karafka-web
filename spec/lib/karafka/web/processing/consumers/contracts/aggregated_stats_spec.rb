# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:stats) do
    {
      batches: 10,
      messages: 100,
      retries: 5,
      dead: 2,
      errors: 3,
      busy: 4,
      enqueued: 6,
      threads_count: 5,
      processes: 2,
      rss: 512.45,
      listeners_count: 3,
      utilization: 70.2,
      lag_stored: 50,
      lag: 10
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(stats)).to be_success
    end
  end

  %i[
    batches messages retries dead errors busy enqueued threads_count processes listeners_count
  ].each do |key|
    context "when #{key} is negative" do
      before { stats[key] = -1 }

      it { expect(contract.call(stats)).not_to be_success }
    end

    context "when #{key} is not a number" do
      before { stats[key] = 'test' }

      it { expect(contract.call(stats)).not_to be_success }
    end

    context "when #{key} is float" do
      before { stats[key] = 1.2 }

      it { expect(contract.call(stats)).not_to be_success }
    end
  end

  %i[
    rss
    utilization
  ].each do |key|
    context "when #{key} is negative" do
      before { stats[key] = -1 }

      it { expect(contract.call(stats)).not_to be_success }
    end

    context "when #{key} is not a number" do
      before { stats[key] = 'test' }

      it { expect(contract.call(stats)).not_to be_success }
    end
  end

  %i[
    lag_stored
    lag
  ].each do |key|
    context "when #{key} is not a number" do
      before { stats[key] = 'test' }

      it { expect(contract.call(stats)).not_to be_success }
    end
  end
end
