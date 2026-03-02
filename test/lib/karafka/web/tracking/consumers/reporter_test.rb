# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  describe "#active?" do
    context "when producer is not yet created" do
      before { allow(Karafka).to receive(:producer).and_return(nil) }

      it { assert_equal(false, reporter.active?) }
    end

    context "when producer is not active" do
      before { allow(Karafka.producer.status).to receive(:active?).and_return(false) }

      it { assert_equal(false, reporter.active?) }
    end

    context "when producer exists but karafka is not even initializing" do
      before { allow(Karafka::App).to receive(:initializing?).and_return(true) }

      it { assert_equal(false, reporter.active?) }
    end

    context "when producer exists but karafka is not initialized" do
      before do
        allow(Karafka::App).to receive_messages(
          initializing?: false,
          initialized?: true
        )
      end

      it { assert_equal(false, reporter.active?) }
    end

    context "when producer exists and is active and server is running" do
      before do
        allow(Karafka::App).to receive_messages(
          initializing?: false,
          initialized?: false
        )
      end

      it { assert_equal(true, reporter.active?) }
    end
  end
end
