# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Contracts for data the Web UI receives from requests
        module Contracts
          # Validates a topic name taken from a request against the Kafka topic naming rules, so
          # a name Kafka cannot have is rejected before any cluster call
          class TopicName < Web::Contracts::Base
            # Characters Kafka allows in a topic name
            TOPIC_NAME_REGEXP = /\A[a-zA-Z0-9._-]+\z/

            # Maximum length of a Kafka topic name
            MAX_TOPIC_NAME_LENGTH = 249

            # Names Kafka reserves. Longer dot-only names such as `...` are valid
            RESERVED_TOPIC_NAMES = %w[. ..].freeze

            private_constant :TOPIC_NAME_REGEXP, :MAX_TOPIC_NAME_LENGTH, :RESERVED_TOPIC_NAMES

            configure

            required(:topic_name) do |val|
              val.is_a?(String) &&
                val.length <= MAX_TOPIC_NAME_LENGTH &&
                !RESERVED_TOPIC_NAMES.include?(val) &&
                val.match?(TOPIC_NAME_REGEXP)
            end
          end
        end
      end
    end
  end
end
