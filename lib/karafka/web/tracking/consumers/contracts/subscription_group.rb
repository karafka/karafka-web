# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Expected data for each subscription group
          # It's mostly about topics details
          class SubscriptionGroup < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(String) && !val.empty? }
            required(:topics) { |val| val.is_a?(Hash) }

            nested(:state) do
              required(:state) { |val| val.is_a?(String) && !val.empty? }
              required(:join_state) { |val| val.is_a?(String) && !val.empty? }
              required(:stateage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:rebalance_age) { |val| val.is_a?(Integer) && val >= 0 }
              required(:rebalance_cnt) { |val| val.is_a?(Integer) && val >= 0 }
              required(:rebalance_reason) { |val| val.is_a?(String) }
              required(:poll_age) { |val| val.is_a?(Numeric) && val >= 0 }
            end

            virtual do |data, errors|
              next unless errors.empty?

              topic_contract = Topic.new

              data.fetch(:topics).each_value do |details|
                topic_contract.validate!(details)
              end

              nil
            end
          end
        end
      end
    end
  end
end
