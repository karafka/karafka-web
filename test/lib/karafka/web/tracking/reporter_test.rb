# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  describe "#active?" do
    context "when producer is not yet created" do
      before { allow(Karafka::Web).to receive(:producer).and_return(nil) }

      it { refute(reporter.active?) }
    end

    context "when producer is not active" do
      before { allow(Karafka.producer.status).to receive(:active?).and_return(false) }

      it { refute(reporter.active?) }
    end

    context "when producer exists and is active" do
      it { assert(reporter.active?) }
    end
  end
end
