# frozen_string_literal: true

module Karafka
  module Web
    # Karafka itself depends on Thor, so we can use it
    class Cli < Thor
      include ::Karafka::Helpers::Colorize

      # Code that is needed in the `karafka.rb` to connect Web UI to Karafka
      ENABLER_CODE = 'Karafka::Web.enable!'

      private_constant :ENABLER_CODE

      package_name 'Karafka Web'

      desc 'install', 'Installs the Web UI'
      method_option(
        :replication_factor,
        desc: 'Replication factor for created topics',
        default: 1,
        type: :numeric
      )
      # Installs Karafka Web
      def install
        puts
        puts 'Installing Karafka Web UI...'
        puts
        puts 'Creating necessary topics and populating state data...'

        Karafka::Web::Installer.new.bootstrap!(replication_factor: options[:replication_factor])

        puts 'Updating the Karafka boot file...'

        if File.read(Karafka.boot_file).include?(ENABLER_CODE)
          puts "Web UI #{green('already')} installed."
        else
          File.open(Karafka.boot_file, 'a') do |f|
            f << "\n#{ENABLER_CODE}\n"
          end
        end

        puts
        puts("Installation #{green('completed')}. Have fun!")
        puts
      end

      desc 'reset', 'Resets the Web UI by removing all the Web topics and creating them again'
      # Resets Karafka Web
      def reset
        puts
        puts 'Resetting Karafka Web UI...'
        Karafka::Web::Installer.new.reset!
        puts
        puts("Resetting #{green('completed')}. Have fun!")
        puts
      end

      desc 'uninstall', 'Removes all the Web UI topics and the enabled code'
      # Uninstalls Karafka Web
      def uninstall
        puts
        puts 'Uninstalling Karafka Web UI...'
        Karafka::Web::Installer.new.uninstall!

        puts 'Updating the Karafka boot file...'

        karafka_rb = File.readlines(Karafka.boot_file)
        if karafka_rb.any? { |line| line.include?(ENABLER_CODE) }
          karafka_rb.delete_if { |line| line.include?(ENABLER_CODE) }

          File.write(Karafka.boot_file, karafka_rb.join)
        end

        puts
        puts("Uninstalling #{green('completed')}. Goodbye!")
        puts
      end
    end
  end
end
