# frozen_string_literal: true

RSpec.describe_current do
  subject(:contract) { described_class.new }

  let(:stats) do
    {
      batches: 10,
      jobs: 1,
      messages: 100,
      retries: 5,
      dead: 2,
      errors: 3,
      busy: 4,
      enqueued: 6,
      workers: 5,
      processes: 2,
      rss: 512.45,
      listeners: { active: 3, standby: 0 },
      utilization: 70.2,
      lag_hybrid: 50
    }
  end

  context 'when all values are valid' do
    it 'is valid' do
      expect(contract.call(stats)).to be_success
    end
  end

  %i[
    batches jobs messages retries dead errors busy enqueued workers processes
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

  context 'when lag_hybrid is not a number' do
    before { stats[:lag_hybrid] = 'test' }

    it { expect(contract.call(stats)).not_to be_success }
  end

  context 'when checking listeners' do
    context 'when active below 0' do
      before { stats[:listeners][:active] = -1 }

      it { expect(contract.call(stats)).not_to be_success }
    end

    context 'when standby below 0' do
      before { stats[:listeners][:standby] = -1 }

      it { expect(contract.call(stats)).not_to be_success }
    end
  end
end
