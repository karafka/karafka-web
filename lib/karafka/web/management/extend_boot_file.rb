# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Extends the boot file with Web components
      class ExtendBootFile < Base
        # Code that is needed in the `karafka.rb` to connect Web UI to Karafka
        ENABLER_CODE = 'Karafka::Web.enable!'

        # Adds needed code
        def call
          if File.read(Karafka.boot_file).include?(ENABLER_CODE)
            puts "Web UI #{already} installed."
          else
            puts 'Updating the Karafka boot file...'
            File.open(Karafka.boot_file, 'a') do |f|
              f << "\n#{ENABLER_CODE}\n"
            end
            puts "Karafka boot file #{successfully} updated."
          end
        end
      end
    end
  end
end
