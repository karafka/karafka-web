# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
