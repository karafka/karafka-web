# frozen_string_literal: true

module Karafka
  module Web
    class Cli
      # Uninstalls the Web UI
      class Uninstall < Base
        desc 'Removes all the Web UI topics and the enabled code'

        # Uninstalls Karafka Web
        def call
          Karafka::Web::Installer.new.uninstall
        end
      end
    end
  end
end
