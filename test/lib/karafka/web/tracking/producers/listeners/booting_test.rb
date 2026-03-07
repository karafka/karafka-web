# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:scheduler) { Karafka::Web.config.tracking.scheduler }

  let(:event) do
    Karafka::Core::Monitoring::Event.new(
      rand,
      type: "test_type"
    )
  end

  describe "#on_producer_connected" do
    before { scheduler.stubs(:async_call) }

    it "expect to trigger async call" do
      scheduler.expects(:async_call)
      listener.on_producer_connected(event)

    end
  end
end
