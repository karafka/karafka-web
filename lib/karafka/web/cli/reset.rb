# frozen_string_literal: true

module Karafka
  module Web
    class Cli
      # Resets the Web UI
      class Reset < Base
        desc 'Resets the Web UI by removing all the Web topics and creating them again'

        option(
          :replication_factor,
          'Replication factor for created topics',
          Integer,
          ['--replication_factor [FACTOR]']
        )

        # Resets Karafka Web. Removes the topics, creates them again and populates the initial
        # state again. This is useful in case the Web-UI metrics or anything else got corrupted.
        def call
          Karafka::Web::Installer.new.reset(
            replication_factor: compute_replication_factor(options[:replication_factor])
          )
        end
      end
    end
  end
end
