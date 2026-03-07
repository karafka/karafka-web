# frozen_string_literal: true

describe_current do
  let(:scheduler) { described_class.new }

  let(:consumers_reporter) { Karafka::Web.config.tracking.consumers.reporter }
  let(:producers_reporter) { Karafka::Web.config.tracking.producers.reporter }

  before do
    consumers_reporter.stubs(:report)
    producers_reporter.stubs(:report)

    scheduler.stubs(:sleep).raises(StandardError)
  end

  describe "#call" do
    before do
      consumers_reporter.stubs(:active?).returns(true)
      producers_reporter.stubs(:active?).returns(false)
    end

    it "executes only active reporters" do
      consumers_reporter.expects(:report).once
      producers_reporter.expects(:report).never
      assert_raises(StandardError) { scheduler.send(:call) }
    end
  end
end
