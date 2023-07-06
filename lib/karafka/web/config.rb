# frozen_string_literal: true

module Karafka
  module Web
    # Karafka::Web configuration
    class Config
      include ::Karafka::Core::Configurable

      #setting(:secret_key_base, default: false, constructor: ->(default) {
      #    ::Object.const_defined?(:Rails) ? Rails.application.secrets[:secret_key_base] : default
      #  }
      #)

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
        # How often should we report data from a single process
        # You may set it to a lower value in development but in production and scale, every
        # 5 seconds should be enough
        setting :interval, default: 5_000

        setting :consumers do
          # Reports the metrics collected in the sampler
          setting :reporter, default: Tracking::Consumers::Reporter.new

          setting :sampler, default: Tracking::Consumers::Sampler.new

          setting :listeners, default: [
            Tracking::Consumers::Listeners::Status.new,
            Tracking::Consumers::Listeners::Errors.new,
            Tracking::Consumers::Listeners::Statistics.new,
            Tracking::Consumers::Listeners::Pausing.new,
            Tracking::Consumers::Listeners::Processing.new,
            Tracking::Consumers::Listeners::Tags.new
          ]
        end

        setting :producers do
          setting :reporter, default: Tracking::Producers::Reporter.new

          setting :sampler, default: Tracking::Producers::Sampler.new

          setting :listeners, default: [
            Tracking::Producers::Listeners::Errors.new,
            Tracking::Producers::Listeners::Reporter.new
          ]
        end
      end

      # States processing related settings
      setting :processing do
        # Should we actively process reports
        # This can be disabled in case of using a multi-tenant approach where only one of the
        # apps should materialize the state
        setting :active, default: true

        # What should be the consumer group name for web consumer
        setting :consumer_group, default: 'karafka_web'

        # How often should we report the aggregated state
        setting :interval, default: 1_000

        setting :consumers do
          setting :aggregator, default: Processing::Consumers::Aggregator.new
        end
      end

      setting :ui do
        setting :explorer do
          # On a per topic view it is expensive (one call per partition) to get offsets and
          # manage the states for aggregated view.
          #
          # This is the max partitions we query for and if there are more, their data will not be
          # displayed and we will show a warning. This prevents the system from being overloaded
          # as for the negative lookups we need to perform additionals calls to Kafka
          #
          # If the system is responsive for you with this number, you can increase it to match
          # your cluster setup
          #
          # librdkafka currently does not support batch watermark offsets aggregations and this is
          # why this limit is introduced.
          setting :max_aggregable_partitions, default: 50

          # Should the payload be decrypted for the Pro Web UI. Default to `false` due to security
          # reasons
          setting :decrypt, default: false
        end

        # How many elements should we display on pages that support pagination
        setting :per_page, default: 25
      end
    end
  end
end
