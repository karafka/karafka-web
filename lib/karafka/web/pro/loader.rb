# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      # Loader requires and loads all the pro components only when they are needed
      class Loader
        class << self
          # This loads the pro components into memory in case someone required karafka-web prior
          # to the license usage. This can happen for users with complex require flows, where
          # Karafka license is not part of the standard flow
          #
          # In such cases Web may not notice that Karafka should operate in a Pro mode when it is
          # being required via Zeitwerk. In such cases we load Pro components prior to the setup.
          def load_on_late_setup
            return if defined?(Karafka::Web::Pro::Commanding)

            loader = Zeitwerk::Loader.new
            loader.push_dir(
              File.join(Karafka::Web.gem_root, 'lib/karafka/web/pro'),
              namespace: Karafka::Web::Pro
            )

            loader.setup
            loader.eager_load
          end

          # Loads all the Web UI pro components and configures them wherever it is expected
          # @param config [Karafka::Core::Configurable::Node] web config that we can alter with pro
          #   components
          def pre_setup_all(config)
            # Expand the config with commanding configuration
            config.instance_eval do
              setting(:commanding, default: Commanding::Config.config)
            end

            # Expand UI config with extra search capabilities settings
            config.ui.instance_eval do
              setting(:branding, default: Ui::Lib::Branding::Config.config)
              setting(:policies, default: Ui::Lib::Policies::Config.config)
              setting(:search, default: Ui::Lib::Search::Config.config)

              setting :topics do
                setting :management do
                  # Should we allow users to manage topics (edit config, resize, etc) from the UI
                  setting(:active, default: true)
                end
              end
            end
          end

          # Runs post setup features configuration operations
          #
          # @param config [Karafka::Core::Configurable::Node]
          def post_setup_all(config)
            Commanding.post_setup(config)
            Ui::Lib::Branding.post_setup(config)
            Ui::Lib::Policies.post_setup(config)
            Ui::Lib::Search.post_setup(config)

            config.commanding.listeners.each do |listener|
              ::Karafka::App.monitor.subscribe(listener)
            end
          end
        end
      end
    end
  end
end
