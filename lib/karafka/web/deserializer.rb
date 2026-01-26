# frozen_string_literal: true

module Karafka
  module Web
    # Web reporting deserializer
    #
    # @note We use `symbolize_names` because we want to use the same convention of hash building
    #   for producing, consuming and displaying metrics related data
    #
    # @note We have to check if we compress the data, because older Web-UI versions were not
    #   compressing the payload.
    class Deserializer
      # @param message [::Karafka::Messages::Message]
      # @return [Object] deserialized data
      def call(message)
        raw_payload = if message.headers.key?("zlib")
          Zlib::Inflate.inflate(message.raw_payload)
        else
          message.raw_payload
        end

        ::JSON.parse(
          raw_payload,
          symbolize_names: true,
          # We allow duplicates keys because of a fixed bug that was causing duplicated process
          # ids to leak into the consumers states data. Once a proper migration is written, this
          # can be retired
          # @see https://github.com/karafka/karafka-web/issues/741
          allow_duplicate_key: true
        )
      end
    end
  end
end
