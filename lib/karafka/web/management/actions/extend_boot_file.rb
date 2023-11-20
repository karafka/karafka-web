# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Extends the boot file with Web components
        class ExtendBootFile < Base
          # Code that is needed in the `karafka.rb` to connect Web UI to Karafka
          ENABLER_CODE = 'Karafka::Web.enable!'

          # Template with initial Web UI configuration
          # Session secret needs to be set per user and per env
          SETUP_TEMPLATE = <<~CONFIG.freeze
            Karafka::Web.setup do |config|
              # You may want to set it per ENV. This value was randomly generated.
              config.ui.sessions.secret = '#{SecureRandom.hex(32)}'
            end

            #{ENABLER_CODE}
          CONFIG

          # Adds needed code
          def call
            if File.read(Karafka.boot_file).include?(ENABLER_CODE)
              puts "Web UI #{already} installed."
            else
              puts 'Updating the Karafka boot file...'
              File.open(Karafka.boot_file, 'a') do |f|
                f << "\n#{SETUP_TEMPLATE}\n"
              end
              puts "Karafka boot file #{successfully} updated."
            end
          end
        end
      end
    end
  end
end
