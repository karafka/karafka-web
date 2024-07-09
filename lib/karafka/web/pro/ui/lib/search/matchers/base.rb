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
