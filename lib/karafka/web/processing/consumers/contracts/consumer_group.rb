# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Ingest expectations for each consumer group of a report
          class ConsumerGroup < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(String) }
            required(:subscription_groups) { |val| val.is_a?(Hash) && val.values.all?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              subscription_group_contract = SubscriptionGroup.new

              data.fetch(:subscription_groups).flat_map do |sg_id, details|
                subscription_group_contract.call(details).errors.map do |path, message|
                  [[:subscription_groups, sg_id, path], message]
                end
              end
            end
          end
        end
      end
    end
  end
end
