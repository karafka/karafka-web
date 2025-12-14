# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for models representing pieces of data about Karafka setup
      module Models
        # Representation of data of a Karafka subscription group
        class SubscriptionGroup < Lib::HashProxy
          # @return [String, false] the group.instance.id for static group membership, or false if
          #   not configured. We need an explicit method because HashProxy#deep_find returns nil
          #   for both missing keys and keys with nil values, causing method_missing to raise.
          def instance_id
            self[:instance_id]
          end

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
