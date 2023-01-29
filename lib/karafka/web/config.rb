# frozen_string_literal: true

module Karafka
  module Web
    # Karafka::Web configuration
    class Config
      include ::Karafka::Core::Configurable

      # How long do we consider the process alive without receiving status info about it
      # For this long we also display dead processes (shutdown) in the UI
      # This is used both in the processing for eviction and in the UI
      setting :ttl, default: 30_000

      # Topics naming - used for processing and UI
      setting :topics do
        # All the errors encountered will be dispatched to this topic for inspection
        setting :errors, default: 'karafka_errors'

        setting :consumers do
          # Reports containing particular consumer processes. This topic contains the heartbeat
          # information sent from each consumer process.
          setting :reports, default: 'karafka_consumers_reports'

          # Topic for storing states aggregated info
          setting :states, default: 'karafka_consumers_states'
        end
      end

      # Tracking and reporting related settings
      setting :tracking do
        # Collects the metrics we will be dispatching
        # Tracks and reports the collected metrics
        setting :reporter, default: Tracking::Reporter.new

        # How often should we report data from a single process
        # You may set it to a lower value in development but in production and scale, every
        # 5 seconds should be enough
        setting :interval, default: 5_000

        setting :consumers do
          setting :sampler, default: Tracking::Consumers::Sampler.new

          setting :listeners, default: [
            Tracking::Consumers::Listeners::Status.new,
            Tracking::Consumers::Listeners::Errors.new,
            Tracking::Consumers::Listeners::Statistics.new,
            Tracking::Consumers::Listeners::Pausing.new,
            Tracking::Consumers::Listeners::Processing.new
          ]
        end

        setting :producers do
          setting :listeners, default: []
        end
      end

      # States processing related settings
      setting :processing do
        # What should be the consumer group name for web consumer
        setting :consumer_group, default: 'karafka_web'

        # How often should we report the aggregated state
        setting :interval, default: 1_000

        setting :consumers do
          setting :aggregator, default: Processing::Consumers::Aggregator.new
        end
      end

      setting :ui do
        # Should the payload be decrypted for the Pro Web UI. Default to `false` due to security
        # reasons
        setting :decrypt, default: false

        # How many elements should we display on pages that support pagination
        setting :per_page, default: 25
      end
    end
  end
end
