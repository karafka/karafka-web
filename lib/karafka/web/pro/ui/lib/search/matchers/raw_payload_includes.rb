# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Matchers
              # Checks for phrase existence in the raw payload
              #
              # @note It is case sensitive
              # @note Ignores encoding issues
              class RawPayloadIncludes < Base
                # @param message [Karafka::Messages::Message]
                # @param phrase [String]
                # @return [Boolean] does message raw payload contain the phrase
                def call(message, phrase)
                  message.raw_payload.include?(phrase)
                # String matching on compressed data may fail
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
