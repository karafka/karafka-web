# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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

                    if raw_header_value.is_a?(Array)
                      raw_header_value.each do |raw_header_sub_value|
                        return true if safe_include?(raw_header_sub_value, phrase)
                      end
                    elsif safe_include?(raw_header_value, phrase)
                      return true
                    end
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
