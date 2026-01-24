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
            # Namespace for search matchers
            # Matcher is what "searches" a message or its parts for a given phrase
            module Matchers
              # Base class for all the search matchers
              # Each matcher needs to have a class `#name` method and needs to respond to `#call`
              class Base
                # @param phrase [String] string phrase for search
                # @param message [Karafka::Messages::Message] message in which we search
                # @return [Boolean] true if found, otherwise false
                def call(phrase, message)
                  raise NotImplementedError, 'Implement in a subclass'
                end

                class << self
                  # @return [String] name of the matcher based on the class name
                  def name
                    # Insert a space before each uppercase letter, except the first one
                    spaced_string = to_s.split('::').last.gsub(/(?<!^)([A-Z])/, ' \1')

                    # Convert the first letter to uppercase and the rest to lowercase
                    spaced_string[0].upcase + spaced_string[1..].downcase
                  end

                  # Allows to disable/enable certain matches that may be specific to certain types
                  # of data per topic. By default matchers are always active
                  #
                  # @param _topic_name [String] name of the topic in the explorer
                  # @return [Boolean] should this matcher be active in the given topic
                  def active?(_topic_name)
                    true
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
