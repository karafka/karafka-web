# frozen_string_literal: true

%w[
  karafka
  roda
  etc
  open3
  zlib
  securerandom
].each { |lib| require lib }

module Karafka
  # Karafka Web UI + Karafka web monitoring
  module Web
    class << self
      # @return [WaterDrop::Producer, nil] waterdrop messages producer or nil if not yet fully
      #   initialized. It may not be fully initialized until the configuration is done
      def producer
        @producer ||= Web.config.producer
      end

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

      # Activates all the needed routing and sets up listener, etc
      # This needs to run **after** the optional configuration of the web component
      def enable!
        # Make sure config is as expected
        # It should be configured before enabling the Web UI
        Contracts::Config.new.validate!(config.to_h)

        Installer.new.enable!

        # Inject correct settings for the Web-UI sessions plugin based on the user configuration
        # We cannot configure this automatically like other Roda plugins because it requires safe
        # custom values provided by our user
        App.engine.plugin(:sessions, **config.ui.sessions.to_h)
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
