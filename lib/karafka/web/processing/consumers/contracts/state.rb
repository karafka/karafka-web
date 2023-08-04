# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Consumer tracking related contracts
        module Contracts
          # Contract used to ensure the consistency of the data generated to the consumers states
          # topic
          class State < Web::Contracts::Base
            configure

            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:stats) { |val| val.is_a?(Hash) }
            required(:processes) { |val| val.is_a?(Hash) }

            virtual do |data, errors|
              next unless errors.empty?

              Contracts::AggregatedStats.new.validate!(data.fetch(:stats))

              nil
            end

            virtual do |data, errors|
              next unless errors.empty?

              process_contract = Contracts::Process.new

              data.fetch(:processes).each_value do |details|
                process_contract.validate!(details)
              end

              nil
            end
          end
        end
      end
    end
  end
end
