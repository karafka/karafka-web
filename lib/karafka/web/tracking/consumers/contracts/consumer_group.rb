# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        # Consumer tracking related contracts
        module Contracts
          # Expected data for each consumer group
          # It's mostly about topics details
          class ConsumerGroup < BaseContract
            configure

            required(:id) { |val| val.is_a?(String) && !val.empty? }
            required(:topics) { |val| val.is_a?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              topic_contract = Topic.new

              data.fetch(:topics).each do |_topic_name, details|
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
