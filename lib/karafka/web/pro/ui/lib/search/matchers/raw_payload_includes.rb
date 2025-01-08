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
              # Checks for phrase existence in the raw payload
              # If raw payload has a `zlib` header, it tries to decompress it
              # (without de-serializing). We decompress because internal web ui topics (including
              # errors topic) use Ruby specific zlib compression.
              #
              # @note It is case sensitive
              # @note Ignores encoding issues
              # @note Decompresses if zlib is used
              class RawPayloadIncludes < Base
                # @param message [Karafka::Messages::Message]
                # @param phrase [String]
                # @return [Boolean] does message raw payload contain the phrase
                def call(message, phrase)
                  # raw payload can be nil for tombstone events
                  return false unless message.raw_payload

                  build_matchable_payload(message).include?(phrase)
                # String matching on compressed data may fail
                rescue Encoding::CompatibilityError
                  false
                end

                private

                # Checks whether decompression is needed and if yes does it. Does not deserialize
                #   the payload itself.
                # @param message [Karafka::Messages::Message]
                # @return [String] decompressed payload
                def build_matchable_payload(message)
                  raw_payload = message.raw_payload

                  return raw_payload unless message.raw_headers.key?('zlib')

                  Zlib::Inflate.inflate(raw_payload)
                rescue Zlib::Error
                  raw_payload
                end
              end
            end
          end
        end
      end
    end
  end
end
