# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        # Consumer tracking related contracts
        module Contracts
          # Expected data for each consumer group
          # It's mostly about subscription groups details
          class ConsumerGroup < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(String) && !val.empty? }
            required(:subscription_groups) { |val| val.is_a?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              subscription_group_contract = SubscriptionGroup.new

              data.fetch(:subscription_groups).each_value do |details|
                subscription_group_contract.validate!(details)
              end

              nil
            end
          end
        end
      end
    end
  end
end
