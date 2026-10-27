# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Ingest expectations for each subscription group of a report
          class SubscriptionGroup < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(String) }
            required(:instance_id) { |val| val == false || val.is_a?(String) }
            required(:topics) { |val| val.is_a?(Hash) && val.values.all?(Hash) }

            nested(:state) do
              required(:join_state) { |val| val.is_a?(String) }
              required(:rebalance_reason) { |val| val.is_a?(String) }
              required(:stateage) { |val| val.is_a?(Integer) }
              required(:rebalance_age) { |val| val.is_a?(Integer) }
              required(:rebalance_cnt) { |val| val.is_a?(Integer) }
              required(:poll_age) { |val| val.is_a?(Numeric) }
            end

            virtual do |data, errors|
              next unless errors.empty?

              topic_contract = Topic.new

              data.fetch(:topics).flat_map do |topic_name, details|
                topic_contract.call(details).errors.map do |path, message|
                  [[:topics, topic_name, path], message]
                end
              end
            end
          end
        end
      end
    end
  end
end
