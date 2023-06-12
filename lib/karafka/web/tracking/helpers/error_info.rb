# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for tracking related helpers
      module Helpers
        # Module containing some helper methods useful for extracting extra errors info
        module ErrorInfo
          # Extracts the basic error info
          #
          # @param error [StandardError] error that occurred
          # @return [Array<String, String, String>] array with error name, message and backtrace
          def extract_error_info(error)
            app_root = "#{::Karafka.root}/"

            gem_home = if ENV.key?('GEM_HOME')
                         ENV['GEM_HOME']
                       else
                         File.expand_path(File.join(Karafka.gem_root.to_s, '../'))
                       end

            gem_home = "#{gem_home}/"

            backtrace = error.backtrace || []
            backtrace.map! { |line| line.gsub(app_root, '') }
            backtrace.map! { |line| line.gsub(gem_home, '') }

            [
              error.class.name,
              extract_error_message(error),
              backtrace.join("\n")
            ]
          end

          # @param error [StandardError] error that occurred
          # @return [String] formatted exception message
          def extract_error_message(error)
            error_message = error.message.to_s[0, 10_000]
            error_message.force_encoding('utf-8')
            error_message.scrub! if error_message.respond_to?(:scrub!)
            error_message
          rescue StandardError
            '!!! Error message extraction failed !!!'
          end
        end
      end
    end
  end
end
