# frozen_string_literal: true

RSpec.describe_current do
  subject(:listener) { described_class.new }

  let(:sampler) { instance_double(Karafka::Web::Tracking::Producers::Sampler) }
  let(:reporter) { instance_double(Karafka::Web::Tracking::Producers::Reporter) }

  before do
    allow(Karafka::Web.config.tracking.producers).to receive_messages(
      sampler: sampler,
      reporter: reporter
    )
  end

  describe 'module inclusion and delegation' do
    it 'includes Karafka::Core::Helpers::Time' do
      expect(described_class.ancestors).to include(Karafka::Core::Helpers::Time)
    end

    it 'extends Forwardable for delegation' do
      expect(described_class.singleton_class.ancestors).to include(Forwardable)
    end

    it 'has time helper methods available' do
      expect(listener).to respond_to(:monotonic_now)
      expect(listener).to respond_to(:float_now)
    end
  end

  describe 'sampler delegation' do
    describe '#track' do
      it 'delegates to sampler with block' do
        allow(sampler).to receive(:track).and_yield(sampler)

        yielded_sampler = nil
        listener.track do |s|
          yielded_sampler = s
        end

        expect(sampler).to have_received(:track)
        expect(yielded_sampler).to eq(sampler)
      end

      it 'caches the sampler instance' do
        allow(sampler).to receive(:track)

        listener.track {}
        listener.track {}

        # Should only call the config once due to memoization
        expect(Karafka::Web.config.tracking.producers).to have_received(:sampler).once
      end
    end

    it 'responds to track method' do
      expect(listener).to respond_to(:track)
    end
  end

  describe 'reporter delegation' do
    describe '#report' do
      it 'delegates to reporter' do
        allow(reporter).to receive(:report)

        listener.report

        expect(reporter).to have_received(:report)
      end
    end

    it 'responds to report method' do
      expect(listener).to respond_to(:report)
    end

    it 'caches the reporter instance' do
      allow(reporter).to receive(:report)

      listener.report
      listener.report

      # Should only call the config once due to memoization
      expect(Karafka::Web.config.tracking.producers).to have_received(:reporter).once
    end
  end

  describe 'integration behavior' do
    before do
      allow(sampler).to receive(:track)
      allow(reporter).to receive(:report)
      allow(reporter).to receive(:report)
    end

    it 'can be used as a base class for specific producer listeners' do
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
      event_data = { messages_sent: 10, producer_id: 'producer_1' }

      allow(sampler).to receive(:track).and_yield(sampler)
      allow(reporter).to receive(:report)

      child_listener.on_producer_event(event_data)

      expect(sampler).to have_received(:track)
      expect(reporter).to have_received(:report)
    end

    it 'maintains separate listener instances' do
      listener1 = described_class.new
      listener2 = described_class.new

      # Instances should be different but use same delegation
      expect(listener1).not_to be(listener2)
      expect(listener1).to respond_to(:track)
      expect(listener2).to respond_to(:track)
    end
  end

  describe 'configuration integration' do
    context 'when producers sampler configuration changes' do
      let(:new_sampler) { instance_double(Karafka::Web::Tracking::Producers::Sampler) }

      it 'uses the newly configured sampler for delegation' do
        # Change configuration and create new instance
        allow(Karafka::Web.config.tracking.producers)
          .to receive(:sampler).and_return(new_sampler)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        allow(new_sampler).to receive(:track)
        new_listener.track {}
        expect(new_sampler).to have_received(:track)
      end
    end

    context 'when producers reporter configuration changes' do
      let(:new_reporter) { instance_double(Karafka::Web::Tracking::Producers::Reporter) }

      it 'uses the newly configured reporter for delegation' do
        # Change configuration and create new instance
        allow(Karafka::Web.config.tracking.producers)
          .to receive(:reporter).and_return(new_reporter)
        new_listener = described_class.new

        # Test that delegation works with new configuration
        allow(new_reporter).to receive(:report)
        new_listener.report
        expect(new_reporter).to have_received(:report)
      end
    end
  end

  describe 'difference from consumers base listener' do
    it 'uses producers configuration instead of consumers' do
      # Test delegation to ensure we're using producers config
      allow(sampler).to receive(:track)
      allow(reporter).to receive(:report)

      listener.track {}
      listener.report

      expect(sampler).to have_received(:track)
      expect(reporter).to have_received(:report)

      # Ensure we're using the producers config, not consumers
      expect(Karafka::Web.config.tracking.producers).to have_received(:sampler)
      expect(Karafka::Web.config.tracking.producers).to have_received(:reporter)
    end

    it 'is properly namespaced under producers' do
      expect(described_class.name).to eq('Karafka::Web::Tracking::Producers::Listeners::Base')
    end
  end

  describe 'producer-specific integration scenarios' do
    before do
      allow(sampler).to receive(:track)
      allow(reporter).to receive(:report)
    end

    it 'can handle producer-specific tracking events' do
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

      allow(sampler).to receive(:track).and_yield(sampler)
      allow(reporter).to receive(:report)

      listener_instance.on_buffer_overflow(overflow_event)

      expect(sampler).to have_received(:track)
      expect(reporter).to have_received(:report)
    end

    it 'can handle async producer events' do
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

      allow(sampler).to receive(:track).and_yield(sampler)
      allow(reporter).to receive(:report)

      listener_instance.on_async_produce_complete(completion_event)

      expect(sampler).to have_received(:track)
      expect(reporter).to have_received(:report)
    end
  end
end
