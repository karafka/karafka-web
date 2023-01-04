# frozen_string_literal: true

module Karafka
  module Web
    # Web reporting deserializer
    #
    # @note We use `symbolize_names` because we want to use the same convention of hash building
    #   for producing, consuming and displaying metrics related data
    class Deserializer
      # @param message [::Karafka::Messages::Message]
      # @return [Object] deserialized data
      def call(message)
        ::JSON.parse(
          message.raw_payload,
          symbolize_names: true
        )
      end
    end
  end
end
