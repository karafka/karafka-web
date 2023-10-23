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

        # Main Web UI reporting scheduler that runs a background thread and reports periodically
        # from the consumer reporter and producer reporter
        setting :scheduler, default: Tracking::Scheduler.new

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
            Tracking::Producers::Listeners::Errors.new
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

        # Specific kafka settings that are tuned to operate within the Web UI interface.
        #
        # Please do not change them unless you know what you are doing as their misconfiguration
        # may cause Web UI to misbehave
        #
        # The settings are inherited as follows:
        #   1. root routing level `kafka` settings
        #   2. admin `kafka` settings
        #   3. web ui `kafka` settings from here
        #
        # Those settings impact ONLY Web UI interface and do not affect other scopes. This is done
        # on purpose as we want to improve responsiveness of the interface by tuning some of the
        # settings and this is not that relevant for processing itself.
        #
        # option [Hash] extra changes to the default admin kafka settings
        setting :kafka, default: {
          # optimizes the responsiveness of the Web UI in three scenarios:
          #   - topics to which writes happen only in transactions so EOF is yield faster
          #   - heavily compacted topics
          #   - Web UI topics read operations when using transactional producer
          #
          # This can be configured to be higher if you do not use transactional WaterDrop producer.
          # This value is used when last message (first from the high watermark offset) is the
          # transaction commit message. In cases like this the EOF gets propagated after this time
          # so we have to wait. Default 500ms means, that for some views, where we take our data
          # that might have been committed via transactional producer, we would wait for 1 second
          # to get needed data. If you are experiencing timeouts or other issues with the Web IU
          # interface, you can increase this.
          'fetch.wait.max.ms': 100
        }
      end
    end
  end
end
