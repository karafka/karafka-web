# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
