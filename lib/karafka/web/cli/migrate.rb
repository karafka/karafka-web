# frozen_string_literal: true

module Karafka
  module Web
    class Cli
      # Migrates the Web UI topics and states if needed
      class Migrate < Base
        desc 'Runs necessary migrations of Web UI topics and states'

        option(
          :replication_factor,
          'Replication factor for created topics',
          Integer,
          ['--replication_factor [FACTOR]']
        )

        # Creates new topics (if any) and populates missing data.
        # It does **not** remove topics and will not populate data if it is already there.
        #
        # Useful in two scenarios:
        #   1. When setting up Web-UI in a new environment, so the Web-UI has the proper initial
        #      state.
        #   2. When upgrading Web-UI in-between versions that would require extra topics and/or
        #      extra states populated.
        def call
          Karafka::Web::Installer.new.migrate(
            replication_factor: compute_replication_factor(options[:replication_factor])
          )
        end
      end
    end
  end
end
