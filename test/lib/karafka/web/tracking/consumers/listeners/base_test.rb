# frozen_string_literal: true

describe_current do
  let(:listener) { described_class.new }

  let(:sampler) { stub }
  let(:reporter) { stub }

  before do
    Karafka::Web.config.tracking.consumers.stubs(:sampler).returns(sampler)
    Karafka::Web.config.tracking.consumers.stubs(:reporter).returns(reporter)
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

        Karafka::Web.config.tracking.consumers.expects(:sampler).once.returns(sampler)
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

    describe "#report!" do
      it "delegates to reporter" do
        reporter.expects(:report!)
        listener.report!
      end
    end

    it "responds to report methods" do
      assert_respond_to(listener, :report)
      assert_respond_to(listener, :report!)
    end

    it "caches the reporter instance" do
      reporter.stubs(:report)

      Karafka::Web.config.tracking.consumers.expects(:reporter).once.returns(reporter)
      listener.report
      listener.report

      # Should only call the config once due to memoization
    end
  end

  describe "integration behavior" do
    before do
      sampler.stubs(:track)
      reporter.stubs(:report)
      reporter.stubs(:report!)
    end

    it "can be used as a base class for specific listeners" do
      child_class = Class.new(described_class) do
        def on_some_event(_event)
          track do |sampler|
            # Example of using sampler within track block
            sampler
          end

          report
        end
      end

      child_listener = child_class.new
      event_data = { message: "test" }

      sampler.expects(:track).yields(sampler)
      reporter.expects(:report)

      child_listener.on_some_event(event_data)
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
    context "when sampler configuration changes" do
      let(:new_sampler) { stub }

      it "uses the newly configured sampler for delegation" do
        # Change configuration and create new instance
        Karafka::Web.config.tracking.consumers.stubs(:sampler).returns(new_sampler)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        new_sampler.expects(:track)
        new_listener.track { nil }
      end
    end

    context "when reporter configuration changes" do
      let(:new_reporter) { stub }

      it "uses the newly configured reporter for delegation" do
        # Change configuration and create new instance
        Karafka::Web.config.tracking.consumers.stubs(:reporter).returns(new_reporter)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        new_reporter.expects(:report)
        new_listener.report
      end
    end
  end
end
