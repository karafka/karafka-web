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
        default: false,
        check_default_type: false,
        type: :numeric
      )
      # Installs Karafka Web. Creates all needed topics, populates the data and adds the needed
      # code to `karafka.rb`.
      def install
        Karafka::Web::Installer.new.install(
          replication_factor: compute_replication_factor(options[:replication_factor])
        )
      end

      desc 'migrate', 'Creates necessary topics if not present and populates state data'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: false,
        check_default_type: false,
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
        Karafka::Web::Installer.new.migrate(
          replication_factor: compute_replication_factor(options[:replication_factor])
        )
      end

      desc 'reset', 'Resets the Web UI by removing all the Web topics and creating them again'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: false,
        check_default_type: false,
        type: :numeric
      )
      # Resets Karafka Web. Removes the topics, creates them again and populates the initial state
      # again. This is useful in case the Web-UI metrics or anything else got corrupted.
      def reset
        Karafka::Web::Installer.new.reset(
          replication_factor: compute_replication_factor(options[:replication_factor])
        )
      end

      desc 'uninstall', 'Removes all the Web UI topics and the enabled code'
      # Uninstalls Karafka Web
      def uninstall
        Karafka::Web::Installer.new.uninstall
      end

      private

      # Takes the CLI user provided replication factor but if not present, uses the brokers count
      # to decide. For non-dev clusters (with one broker) we usually want to have replication of
      # two, just to have some redundancy.
      # @param cli_replication_factor [Integer, false] user requested replication factor or false
      #   if we are supposed to compute the factor automatically
      # @return [Integer] replication factor for Karafka Web UI topics
      def compute_replication_factor(cli_replication_factor)
        cli_replication_factor || Ui::Models::ClusterInfo.fetch.brokers.size > 1 ? 2 : 1
      end
    end
  end
end
