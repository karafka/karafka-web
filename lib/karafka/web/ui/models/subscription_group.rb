# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for models representing pieces of data about Karafka setup
      module Models
        # Representation of data of a Karafka subscription group
        class SubscriptionGroup < Lib::HashProxy
          # @return [Array<Topic>] Data of topics belonging to this subscription group
          def topics
            super.values.map do |topic_hash|
              Topic.new(topic_hash)
            end
          end
        end
      end
    end
  end
end
