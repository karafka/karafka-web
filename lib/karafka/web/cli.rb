# frozen_string_literal: true

module Karafka
  module Web
    # Karafka itself depends on Thor, so we can use it
    class Cli < Thor
      include ::Karafka::Helpers::Colorize

      package_name 'Karafka Web'

      desc 'install', 'Installs the Web UI'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: 1,
        type: :numeric
      )
      # Installs Karafka Web. Creates all needed topics, populates the data and adds the needed
      # code to `karafka.rb`.
      def install
        Karafka::Web::Installer.new.install!
      end

      desc 'migrate', 'Creates necessary topics if not present and populates state data'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: 1,
        type: :numeric
      )
      # Creates new topics (if any) and populates missing data.
      # It does **not** remove topics and will not populate data if it is already there.
      #
      # Useful in two scenarios:
      #   1. When setting up Web-UI in a new environment, so the Web-UI has the proper initial
      #      state.
      #   2. When upgrading Web-UI in-between versions that would require extra topics and/or extra
      #      states populated.
      def migrate
        Karafka::Web::Installer.new.migrate!(replication_factor: options[:replication_factor])
      end

      desc 'reset', 'Resets the Web UI by removing all the Web topics and creating them again'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: 1,
        type: :numeric
      )
      # Resets Karafka Web. Removes the topics, creates them again and populates the initial state
      # again. This is useful in case the Web-UI metrics or anything else got corrupted.
      def reset
        Karafka::Web::Installer.new.reset!
      end

      desc 'uninstall', 'Removes all the Web UI topics and the enabled code'
      # Uninstalls Karafka Web
      def uninstall
        Karafka::Web::Installer.new.uninstall!
      end
    end
  end
end
