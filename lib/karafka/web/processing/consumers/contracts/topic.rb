# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Ingest expectations for each topic of a subscription group
          class Topic < Web::Contracts::Base
            configure

            required(:name) { |val| val.is_a?(String) }
            required(:partitions_cnt) { |val| val.is_a?(Integer) }
            required(:partitions) { |val| val.is_a?(Hash) && val.values.all?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              partition_contract = Partition.new

              data.fetch(:partitions).flat_map do |partition_id, details|
                partition_contract.call(details).errors.map do |path, message|
                  [[:partitions, partition_id, path], message]
                end
              end
            end
          end
        end
      end
    end
  end
end
