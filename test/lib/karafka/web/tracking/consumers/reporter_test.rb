# frozen_string_literal: true

describe_current do
  let(:reporter) { described_class.new }

  describe "#active?" do
    context "when producer is not yet created" do
      before { Karafka.stubs(:producer).returns(nil) }

      it { refute(reporter.active?) }
    end

    context "when producer is not active" do
      before { Karafka.producer.status.stubs(:active?).returns(false) }

      it { refute(reporter.active?) }
    end

    context "when producer exists but karafka is not even initializing" do
      before { Karafka::App.stubs(:initializing?).returns(true) }

      it { refute(reporter.active?) }
    end

    context "when producer exists but karafka is not initialized" do
      before do
        Karafka::App.stubs(:initializing?).returns(false)
        Karafka::App.stubs(:initialized?).returns(true)
      end

      it { refute(reporter.active?) }
    end

    context "when producer exists and is active and server is running" do
      before do
        Karafka::App.stubs(:initializing?).returns(false)
        Karafka::App.stubs(:initialized?).returns(false)
      end

      it { assert(reporter.active?) }
    end
  end
end
