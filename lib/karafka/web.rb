# frozen_string_literal: true

%w[
  karafka
  roda
  etc
  open3
].each { |lib| require lib }

module Karafka
  # Karafka Web UI + Karafka web monitoring
  module Web
    class << self
      # @return [String] root path of this gem
      def gem_root
        Pathname.new(File.expand_path('../..', __dir__))
      end

      # Sets up the whole configuration
      # @param [Block] block configuration block
      def setup(&block)
        Config.configure(&block)
      end

      # @return [Karafka::Web::Config] config instance
      def config
        Config.config
      end

      # Creates all the needed topics for the admin UI to work
      #
      # @param replication_factor [Integer]
      def bootstrap_topics!(replication_factor = 1)
        # This topic needs to have one partition
        ::Karafka::Admin.create_topic(
          ::Karafka::Web.config.topics.consumers.states,
          1,
          replication_factor,
          # We care only about the most recent state, previous are irrelevant
          { 'cleanup.policy': 'compact' }
        )

        # This topic needs to have one partition
        ::Karafka::Admin.create_topic(
          ::Karafka::Web.config.topics.consumers.reports,
          1,
          replication_factor,
          # We do not need to to store this data for longer than 7 days as this data is only used
          # to materialize the end states
          # On the other hand we do not want to have it really short-living because in case of a
          # consumer crash, we may want to use this info to catch up and backfill the state
          { 'retention.ms': 7 * 24 * 60 * 60 * 1_000 }
        )

        # All the errors will be dispatched here
        # This topic can have multiple partitions but we go with one by default. A single Ruby
        # process should not crash that often and if there is an expectation of a higher volume
        # of errors, this can be changed by the end user
        ::Karafka::Admin.create_topic(
          ::Karafka::Web.config.topics.errors,
          1,
          replication_factor
        )
      end

      # Activates all the needed routing and sets up listener, etc
      # This needs to run **after** the optional configuration of the web component
      def enable!
        ::Karafka::App.routes.draw do
          web_deserializer = ::Karafka::Web::Deserializer.new

          consumer_group ::Karafka::Web.config.processing.consumer_group do
            topic ::Karafka::Web.config.topics.consumers.reports do
              # Since we materialize state in intervals, we can poll for half of this time without
              # impacting the reporting responsiveness
              max_wait_time ::Karafka::Web.config.processing.interval / 2
              max_messages 1_000
              consumer ::Karafka::Web::Processing::Consumer
              deserializer web_deserializer
              manual_offset_management true
            end

            topic ::Karafka::Web.config.topics.consumers.states do
              active false
              deserializer web_deserializer
            end

            topic ::Karafka::Web.config.topics.errors do
              active false
              deserializer web_deserializer
            end
          end
        end

        ::Karafka::Web.config.tracking.consumers.listeners.each do |listener|
          ::Karafka.monitor.subscribe(listener)
        end
      end
    end
  end
end

loader = Zeitwerk::Loader.new
# Make sure pro is not loaded unless Pro
loader.ignore(Karafka::Web.gem_root.join('lib/karafka/web/ui/pro'))

# If license is detected, we can use loader without limitations
Karafka::Licenser.detect do
  loader = Zeitwerk::Loader.new
end

root = File.expand_path('..', __dir__)
loader.tag = 'karafka-web'
loader.inflector = Zeitwerk::GemInflector.new("#{root}/karafka/web.rb")
loader.push_dir(root)

loader.setup
loader.eager_load
