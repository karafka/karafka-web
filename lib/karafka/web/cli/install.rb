# frozen_string_literal: true

module Karafka
  module Web
    class Cli
      # Installs Web UI
      class Install < Base
        desc 'Installs the Web UI'

        option(
          :replication_factor,
          'Replication factor for created topics',
          Integer,
          ['--replication_factor [FACTOR]']
        )

        # Installs Karafka Web. Creates all needed topics, populates the data and adds the needed
        # code to `karafka.rb`.
        def call
          Karafka::Web::Installer.new.install(
            replication_factor: compute_replication_factor(options[:replication_factor])
          )
        end
      end
    end
  end
end
