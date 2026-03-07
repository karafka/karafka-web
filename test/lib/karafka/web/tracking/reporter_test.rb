# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  describe "#active?" do
    context "when producer is not yet created" do
      before { Karafka::Web.stubs(:producer).returns(nil) }

      it { refute(reporter.active?) }
    end

    context "when producer is not active" do
      before { Karafka.producer.status.stubs(:active?).returns(false) }

      it { refute(reporter.active?) }
    end

    context "when producer exists and is active" do
      it { assert(reporter.active?) }
    end
  end
end
