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
        enable!
        puts
        puts 'Installing Karafka Web UI...'
        puts
        Management::Actions::ExtendBootFile.new.call
        puts
        puts 'Creating necessary topics and populating state data...'
        puts
        Management::Actions::CreateTopics.new.call(replication_factor)
        wait_for_topics
        Management::Actions::CreateInitialStates.new.call
        puts
        puts 'Running data migrations...'
        Management::Actions::MigrateStatesData.new.call
        puts
        puts("Installation #{green('completed')}. Have fun!")
        puts
      end

      # Creates missing topics and missing zero states. Needs to run for each environment where we
      # want to use Web-UI
      #
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def migrate(replication_factor: 1)
        enable!
        puts
        puts 'Creating necessary topics and populating state data...'
        puts
        Management::Actions::CreateTopics.new.call(replication_factor)
        wait_for_topics
        Management::Actions::CreateInitialStates.new.call
        puts
        puts 'Running data migrations...'
        Management::Actions::MigrateStatesData.new.call
        puts
        puts("Migration #{green('completed')}. Have fun!")
        puts
      end

      # Removes all the Karafka topics and creates them again with the same replication factor
      # @param replication_factor [Integer] replication factor we want to use (1 by default)
      def reset(replication_factor: 1)
        enable!
        puts
        puts 'Resetting Karafka Web UI...'
        puts
        Management::Actions::DeleteTopics.new.call
        puts
        Management::Actions::CreateTopics.new.call(replication_factor)
        wait_for_topics
        Management::Actions::CreateInitialStates.new.call
        puts
        puts 'Running data migrations...'
        Management::Actions::MigrateStatesData.new.call
        puts
        puts("Resetting #{green('completed')}. Have fun!")
        puts
      end

      # Removes all the Karafka Web topics and cleans after itself.
      def uninstall
        enable!
        puts
        puts 'Uninstalling Karafka Web UI...'
        puts
        Management::Actions::DeleteTopics.new.call
        Management::Actions::CleanBootFile.new.call
        puts
        puts("Uninstalling #{green('completed')}. Goodbye!")
        puts
      end

      # Enables the Web-UI in the karafka app. Sets up needed routes and listeners.
      def enable!
        Management::Actions::Enable.new.call
      end

      private

      # Waits with a message, that we are waiting on topics
      # This is not doing much, just waiting as there are some cases that it takes a bit of time
      # for Kafka to actually propagate new topics knowledge across the cluster. We give it that
      # bit of time just in case.
      def wait_for_topics
        puts
        print 'Waiting for the topics to synchronize in the cluster'
        wait(5)
        puts
      end

      # Waits for given number of seconds and prints `.` every second.
      # @param time_in_seconds [Integer] time of wait
      def wait(time_in_seconds)
        time_in_seconds.times do
          sleep(1)
          print '.'
        end

        print "\n"
      end
    end
  end
end
