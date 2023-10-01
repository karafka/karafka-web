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

          # Topic for storing consumers historical metrics info
          setting :metrics, default: 'karafka_consumers_metrics'
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
            Tracking::Consumers::Listeners::Tags.new,
            Tracking::Consumers::Listeners::Connections.new
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

        # How often should we report the aggregated state and metrics
        # By default we flush the states twice as often as the data reporting.
        # This will allow us to have closer to real-time reporting.
        setting :interval, default: 2_500
      end

      setting :ui do
        # UI session settings
        # Should be set per ENV.
        setting :sessions do
          # Cookie key name
          setting :key, default: '_karafka_session'

          # Secret for the session cookie
          setting :secret, default: SecureRandom.hex(32)
        end

        # UI cache to improve performance of views that reuse states that are not often changed
        setting :cache, default: Ui::Lib::TtlCache.new(
          # Use the TTL for internal cache in prod but invalidate quickly in other environments,
          # as for example in development things may change frequently
          Karafka.env.production? ? 60_000 * 5 : 5_000
        )

        # Should we display internal topics of Kafka. The once starting with `__`
        # By default we do not display them as they are not usable from regular users perspective
        setting :show_internal_topics, default: false

        # How many elements should we display on pages that support pagination
        setting :per_page, default: 25

        # Time beyond which the last stable offset freeze is considered a risk
        # (unless same as high). This is used to show on the UI that there may be a hanging
        # transaction that will cause given consumer group to halt processing and wait
        setting :lso_threshold, default: 5 * 60 * 1_000

        # Allows to manage visibility of payload, headers and message key in the UI
        # In some cases you may want to limit what is being displayed due to the type of data you
        # are dealing with
        setting :visibility_filter, default: Ui::Models::VisibilityFilter.new
      end
    end
  end
end
