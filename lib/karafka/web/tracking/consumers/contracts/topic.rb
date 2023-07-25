# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Expected topic information that needs to go out
          class Topic < Web::Contracts::Base
            configure

            required(:name) { |val| val.is_a?(String) && !val.empty? }
            required(:partitions) { |val| val.is_a?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              partition_contract = Partition.new

              data.fetch(:partitions).each_value do |details|
                partition_contract.validate!(details)
              end

              nil
            end
          end
        end
      end
    end
  end
end
