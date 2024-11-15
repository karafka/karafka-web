# frozen_string_literal: true

%w[
  karafka
  roda
  etc
  open3
  zlib
  securerandom
  cgi
  uri
].each { |lib| require lib }

module Karafka
  # Karafka Web UI + Karafka web monitoring
  module Web
    class << self
      # @return [WaterDrop::Producer, nil] waterdrop messages producer or nil if not yet fully
      #   initialized. It may not be fully initialized until the configuration is done
      # @note Do NOT memoize producer as it may be updated after forking
      def producer
        Web.config.producer
      end

      # @return [String] root path of this gem
      def gem_root
        Pathname.new(File.expand_path('../..', __dir__))
      end

      # Sets up the whole configuration
      # @param [Block] block configuration block
      def setup(&block)
        if Karafka.pro?
          require_relative 'web/pro/loader'

          Pro::Loader.load_on_late_setup
          Pro::Loader.pre_setup_all(config)
        end

        Config.configure(&block)

        Pro::Loader.post_setup_all(config) if Karafka.pro?

        @configured = true
      end

      # @return [Karafka::Web::Config] config instance
      def config
        Config.config
      end

      # Activates all the needed routing and sets up listener, etc
      # This needs to run **after** the optional configuration of the web component
      def enable!
        # Run the setup to initialize components if user did not run it prior himself
        setup unless @configured

        # Make sure config is as expected
        # It should be configured before enabling the Web UI
        Contracts::Config.new.validate!(config.to_h)

        Installer.new.enable!

        # Inject correct settings for the Web-UI sessions plugin based on the user configuration
        # We cannot configure this automatically like other Roda plugins because it requires safe
        # custom values provided by our user
        App.engine.plugin(:sessions, **config.ui.sessions.to_h)
      end

      # @return [Array<String>] Web UI slogans we use to encourage people to support Karafka
      def slogans
        @slogans ||= YAML.load_file(
          gem_root.join('config', 'locales', 'slogans.yml')
        ).dig('en', 'slogans')
      end
    end
  end
end

require_relative 'web/inflector'

loader = Zeitwerk::Loader.new

# Make sure pro is not loaded unless Pro
loader.ignore(Karafka::Web.gem_root.join('lib/karafka/web/pro'))

# If license is detected, we can use loader without limitations
Karafka::Licenser.detect do
  loader = Zeitwerk::Loader.new
end

loader.tag = 'karafka-web'
# Use our custom inflector to support migrations
root = File.expand_path('..', __dir__)
loader.inflector = Karafka::Web::Inflector.new("#{root}/karafka/web.rb")
loader.push_dir(root)

loader.setup
loader.eager_load
