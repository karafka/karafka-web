# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Matchers
              # Matcher that searches in the raw headers. If any header key or value matches
              # the phrase, it is true. Otherwise false.
              #
              # @note It is case sensitive
              # @note Ignores encoding issues
              class RawHeaderIncludes < Base
                # @param message [Karafka::Messages::Message]
                # @param phrase [String]
                # @return [Boolean] does message raw headers contain the phrase
                def call(message, phrase)
                  message.raw_headers.each do |raw_header_key, raw_header_value|
                    return true if safe_include?(raw_header_key, phrase)
                    return true if safe_include?(raw_header_value, phrase)
                  end

                  false
                end

                private

                # Checks the inclusion ignoring encoding issues
                # @param string [String] String in which we look
                # @param phrase [String] string for which we look
                # @return [Boolean] true if found, otherwise false
                def safe_include?(string, phrase)
                  string.include?(phrase)
                rescue Encoding::CompatibilityError
                  false
                end
              end
            end
          end
        end
      end
    end
  end
end
