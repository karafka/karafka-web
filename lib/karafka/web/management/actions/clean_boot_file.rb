# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Cleans the boot file from Karafka Web-UI details.
        class CleanBootFile < Base
          # Web-UI enabled code
          ENABLER_CODE = ExtendBootFile::ENABLER_CODE

          private_constant :ENABLER_CODE

          # Removes the Web-UI boot file data
          def call
            karafka_rb = File.readlines(Karafka.boot_file)

            if karafka_rb.any? { |line| line.include?(ENABLER_CODE) }
              puts 'Updating the Karafka boot file...'
              karafka_rb.delete_if { |line| line.include?(ENABLER_CODE) }

              File.write(Karafka.boot_file, karafka_rb.join)
              puts "Karafka boot file #{successfully} updated."
              puts 'Make sure to remove configuration and other customizations as well.'
            else
              puts 'Karafka Web UI components not found in the boot file.'
            end
          end
        end
      end
    end
  end
end
