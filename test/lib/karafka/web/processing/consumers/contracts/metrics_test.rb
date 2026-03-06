# frozen_string_literal: true

describe_current do
  let(:contract) { described_class.new }

  let(:metrics) do
    {
      dispatched_at: Time.now.to_f,
      schema_version: "1.0.0",
      aggregated: {},
      consumer_groups: {}
    }
  end

  context "when all values are valid" do
    it "is valid" do
      assert(contract.call(metrics).success?)
    end
  end

  context "when dispatched_at is negative" do
    before { metrics[:dispatched_at] = -1 }

    it { refute(contract.call(metrics).success?) }
  end

  context "when dispatched_at is not a number" do
    before { metrics[:dispatched_at] = "test" }

    it { refute(contract.call(metrics).success?) }
  end

  context "when schema_version is empty" do
    before { metrics[:schema_version] = "" }

    it { refute(contract.call(metrics).success?) }
  end

  context "when schema_version is not a string" do
    before { metrics[:schema_version] = 123 }

    it { refute(contract.call(metrics).success?) }
  end

  context "when aggregated metrics exist but are not valid" do
    before { metrics[:aggregated] = { days: [[1, { batches: -2 }]] } }

    it { assert_raises(Karafka::Web::Errors::ContractError) { contract.call(metrics) } }
  end

  context "when consumer_groups metrics exist but are not valid" do
    before { metrics[:consumer_groups] = { days: [[1, { "name" => { "topic" => {} } }]] } }

    it { assert_raises(Karafka::Web::Errors::ContractError) { contract.call(metrics) } }
  end
end
