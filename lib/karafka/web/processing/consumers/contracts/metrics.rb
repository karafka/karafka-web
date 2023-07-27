# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Contract that describes the schema for metric reporting
          class Metrics < Web::Contracts::Base
            configure

            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }

            # Ensure, that all aggregated metrics are as expected (values)
            virtual do |data, errors|
              next unless errors.empty?

              stats_contract = Contracts::AggregatedStats.new

              data.fetch(:aggregated).each_value do |range_sample|
                # Older metrics should have been validated previously so we need to check only
                # the most recently materialized one
                stats_contract.validate!(range_sample.last.last)
              end

              nil
            end

            # Ensure that all the consumer groups topics details are as expected
            virtual do |data, errors|
              next unless errors.empty?

              topic_contract = Contracts::TopicStats.new

              data.fetch(:consumer_groups).each_value do |range_sample|
                consumer_group = range_sample.last.last

                consumer_group.each_value do |topics|
                  topics.each_value do |topic_stats|
                    topic_contract.validate!(topic_stats)
                  end
                end
              end

              nil
            end
          end
        end
      end
    end
  end
end
