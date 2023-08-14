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
        raw_payload = if message.headers.key?('zlib')
                        Zlib::Inflate.inflate(message.raw_payload)
                      else
                        message.raw_payload
                      end

        ::JSON.parse(
          raw_payload,
          symbolize_names: true
        )
      end
    end
  end
end
