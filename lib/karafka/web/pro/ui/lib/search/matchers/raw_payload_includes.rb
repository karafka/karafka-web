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
