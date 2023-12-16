# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Representation of data of a Karafka consumer group
        class ConsumerGroup < Lib::HashProxy
          # @return [Array<SubscriptionGroup>] Data of topics belonging to this consumer group
          def subscription_groups
            super
              .values
              .map { |sg_hash| SubscriptionGroup.new(sg_hash) }
              .sort_by(&:id)
          end
        end
      end
    end
  end
end
