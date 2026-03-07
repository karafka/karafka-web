# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { stub() }
  let(:reporter) { stub() }

  before do
    Karafka::Web.config.tracking.producers.stubs(:sampler).returns(sampler)
    Karafka::Web.config.tracking.producers.stubs(:reporter).returns(reporter)
  end

  describe "module inclusion and delegation" do
    it "includes Karafka::Core::Helpers::Time" do
      assert_includes(described_class.ancestors, Karafka::Core::Helpers::Time)
    end

    it "extends Forwardable for delegation" do
      assert_includes(described_class.singleton_class.ancestors, Forwardable)
    end

    it "has time helper methods available" do
      assert_respond_to(listener, :monotonic_now)
      assert_respond_to(listener, :float_now)
    end
  end

  describe "sampler delegation" do
    describe "#track" do
      it "delegates to sampler with block" do
        sampler.expects(:track).yields(sampler)

        yielded_sampler = nil
        listener.track do |s|
          yielded_sampler = s
        end

        assert_equal(sampler, yielded_sampler)
      end

      it "caches the sampler instance" do
        sampler.stubs(:track)

        Karafka::Web.config.tracking.producers.expects(:sampler).once.returns(sampler)
        listener.track { nil }
        listener.track { nil }

        # Should only call the config once due to memoization
      end
    end

    it "responds to track method" do
      assert_respond_to(listener, :track)
    end
  end

  describe "reporter delegation" do
    describe "#report" do
      it "delegates to reporter" do
        reporter.expects(:report)
        listener.report
      end
    end

    it "responds to report method" do
      assert_respond_to(listener, :report)
    end

    it "caches the reporter instance" do
      reporter.stubs(:report)

      Karafka::Web.config.tracking.producers.expects(:reporter).once.returns(reporter)
      listener.report
      listener.report

      # Should only call the config once due to memoization
    end
  end

  describe "integration behavior" do
    before do
      sampler.stubs(:track)
      reporter.stubs(:report)
    end

    it "can be used as a base class for specific producer listeners" do
      child_class = Class.new(described_class) do
        def on_producer_event(_event)
          track do |sampler|
            # Example of using sampler within track block
            sampler
          end
          report
        end
      end

      child_listener = child_class.new
      event_data = { messages_sent: 10, producer_id: "producer_1" }

      sampler.expects(:track).yields(sampler)
      reporter.expects(:report)

      child_listener.on_producer_event(event_data)
    end

    it "maintains separate listener instances" do
      listener1 = described_class.new
      listener2 = described_class.new

      # Instances should be different but use same delegation
      refute_same(listener2, listener1)

      assert_respond_to(listener1, :track)
      assert_respond_to(listener2, :track)
    end
  end

  describe "configuration integration" do
    context "when producers sampler configuration changes" do
      let(:new_sampler) { stub() }

      it "uses the newly configured sampler for delegation" do
        # Change configuration and create new instance
        Karafka::Web.config.tracking.producers.stubs(:sampler).returns(new_sampler)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        new_sampler.expects(:track)
        new_listener.track { nil }
      end
    end

    context "when producers reporter configuration changes" do
      let(:new_reporter) { stub() }

      it "uses the newly configured reporter for delegation" do
        # Change configuration and create new instance
        Karafka::Web.config.tracking.producers.stubs(:reporter).returns(new_reporter)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        new_reporter.expects(:report)
        new_listener.report
      end
    end
  end

  describe "difference from consumers base listener" do
    it "uses producers configuration instead of consumers" do
      # Test delegation to ensure we're using producers config
      Karafka::Web.config.tracking.producers.expects(:sampler).returns(sampler)
      Karafka::Web.config.tracking.producers.expects(:reporter).returns(reporter)
      sampler.expects(:track)
      reporter.expects(:report)

      listener.track { nil }
      listener.report

      # Ensure we're using the producers config, not consumers
    end

    it "is properly namespaced under producers" do
      assert_equal("Karafka::Web::Tracking::Producers::Listeners::Base", described_class.name)
    end
  end

  describe "producer-specific integration scenarios" do
    before do
      sampler.stubs(:track)
      reporter.stubs(:report)
    end

    it "can handle producer-specific tracking events" do
      producer_listener = Class.new(described_class) do
        def on_buffer_overflow(_event)
          track do |sampler|
            # Example of tracking buffer overflow
            sampler
          end
          report # Report normally for producers
        end
      end

      listener_instance = producer_listener.new
      overflow_event = { buffer_size: 1000, messages_lost: 5 }

      sampler.expects(:track).yields(sampler)
      reporter.expects(:report)

      listener_instance.on_buffer_overflow(overflow_event)
    end

    it "can handle async producer events" do
      async_listener = Class.new(described_class) do
        def on_async_produce_complete(_event)
          track do |sampler|
            # Example of tracking async completion
            sampler
          end
          report if should_report?
        end

        private

        def should_report?
          # Example condition for reporting
          true
        end
      end

      listener_instance = async_listener.new
      completion_event = { acks: :all, partition: 0, offset: 12_345 }

      sampler.expects(:track).yields(sampler)
      reporter.expects(:report)

      listener_instance.on_async_produce_complete(completion_event)
    end
  end
end
