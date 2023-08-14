# frozen_string_literal: true

module Karafka
  module Web
    # Responsible for setup of the Web UI and Karafka Web-UI related components initialization.
    class Installer
      include ::Karafka::Helpers::Colorize

      # Creates needed topics and the initial zero state, so even if no `karafka server` processes
      # are running, we can still display the empty UI. Also adds needed code to the `karafka.rb`
      # file.
      #
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def install(replication_factor: 1)
        puts
        puts 'Installing Karafka Web UI...'
        puts
        puts 'Creating necessary topics and populating state data...'
        puts
        Management::CreateTopics.new.call(replication_factor)
        puts
        Management::CreateInitialStates.new.call
        puts
        Management::ExtendBootFile.new.call
        puts
        puts("Installation #{green('completed')}. Have fun!")
        puts
      end

      # Creates missing topics and missing zero states. Needs to run for each environment where we
      # want to use Web-UI
      #
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def migrate(replication_factor: 1)
        puts
        puts 'Creating necessary topics and populating state data...'
        puts
        Management::CreateTopics.new.call(replication_factor)
        Management::CreateInitialStates.new.call
        puts
        puts("Migration #{green('completed')}. Have fun!")
        puts
      end

      # Removes all the Karafka topics and creates them again with the same replication factor
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def reset(replication_factor: 1)
        puts
        puts 'Resetting Karafka Web UI...'
        puts
        Management::DeleteTopics.new.call
        puts
        Management::CreateTopics.new.call(replication_factor)
        puts
        Management::CreateInitialStates.new.call
        puts
        puts("Resetting #{green('completed')}. Have fun!")
        puts
      end

      # Removes all the Karafka Web topics and cleans after itself.
      def uninstall
        puts
        puts 'Uninstalling Karafka Web UI...'
        puts
        Management::DeleteTopics.new.call
        Management::CleanBootFile.new.call
        puts
        puts("Uninstalling #{green('completed')}. Goodbye!")
        puts
      end

      # Enables the Web-UI in the karafka app. Sets up needed routes and listeners.
      def enable!
        Management::Enable.new.call
      end
    end
  end
end
