# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Matchers
              # Checks if the key contains requested phrase
              #
              # @note It is case sensitive
              # @note Ignores encoding issues
              class RawKeyIncludes < Base
                # @param message [Karafka::Messages::Message]
                # @param phrase [String]
                # @return [Boolean] does message raw key contain the phrase
                def call(message, phrase)
                  message.raw_key.to_s.include?(phrase)
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
