# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Main consumer process related reporting schema
          #
          # Any outgoing reporting needs to match this format for it to work with the statuses
          # consumer.
          class Report < BaseContract
            configure

            required(:schema_version) { |val| val.is_a?(String) }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            # We have consumers and producer reports and need to ensure that each is handled
            # in an expected fashion
            required(:type) { |val| val == 'consumer' }

            nested(:process) do
              required(:started_at) { |val| val.is_a?(Numeric) && val.positive? }
              required(:name) { |val| val.is_a?(String) && val.count(':') >= 2 }
              required(:memory_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_total_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_size) { |val| val.is_a?(Integer) && val >= 0 }
              required(:status) { |val| ::Karafka::Status::STATES.key?(val.to_sym) }
              required(:listeners) { |val| val.is_a?(Integer) && val >= 0 }
              required(:concurrency) { |val| val.is_a?(Integer) && val.positive? }
              required(:labels) { |val| val.is_a?(Array) && val.all? { |lab| lab.is_a?(String) } }

              required(:cpu_usage) do |val|
                val.is_a?(Array) &&
                  val.all? { |key| key.is_a?(Numeric) } &&
                  val.all? { |key| key >= -1 } &&
                  val.size == 3
              end
            end

            nested(:versions) do
              required(:karafka) { |val| val.is_a?(String) && !val.empty? }
              required(:waterdrop) { |val| val.is_a?(String) && !val.empty? }
              required(:ruby) { |val| val.is_a?(String) && !val.empty? }
            end

            nested(:stats) do
              required(:busy) { |val| val.is_a?(Integer) && val >= 0 }
              required(:enqueued) { |val| val.is_a?(Integer) && val >= 0 }
              required(:utilization) { |val| val.is_a?(Numeric) && val >= 0 }

              nested(:total) do
                required(:batches) { |val| val.is_a?(Numeric) && val >= 0 }
                required(:messages) { |val| val.is_a?(Numeric) && val >= 0 }
                required(:errors) { |val| val.is_a?(Numeric) && val >= 0 }
                required(:retries) { |val| val.is_a?(Numeric) && val >= 0 }
                required(:dead) { |val| val.is_a?(Numeric) && val >= 0 }
              end
            end

            # Consumer groups have topics that have partitions
            required(:consumer_groups) { |val| val.is_a?(Hash) }

            required(:jobs) { |val| val.is_a?(Array) }

            # Validates that all the data about given consumer group is as expected
            virtual do |data, errors|
              next unless errors.empty?

              cg_contract = ConsumerGroup.new

              # Consumer group id (key) is irrelevant because it is also in the details
              data.fetch(:consumer_groups).each do |_, details|
                cg_contract.validate!(details)
              end

              nil
            end

            # Validates that job reference has all the needed info
            virtual do |data, errors|
              next unless errors.empty?

              job_contract = Job.new

              data.fetch(:jobs).each do |details|
                job_contract.validate!(details)
              end

              nil
            end
          end
        end
      end
    end
  end
end
