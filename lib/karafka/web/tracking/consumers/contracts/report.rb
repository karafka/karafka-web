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
          class Report < Web::Contracts::Base
            configure

            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            # We have consumers and producer reports and need to ensure that each is handled
            # in an expected fashion
            required(:type) { |val| val == 'consumer' }

            nested(:process) do
              required(:started_at) { |val| val.is_a?(Numeric) && val.positive? }
              required(:id) { |val| val.is_a?(String) && val.count(':') >= 2 }
              required(:cpus) { |val| val.is_a?(Integer) && val >= 1 }
              required(:memory_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_total_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_size) { |val| val.is_a?(Integer) && val >= 0 }
              required(:status) { |val| ::Karafka::Status::STATES.key?(val.to_s.to_sym) }
              required(:threads) { |val| val.is_a?(Integer) && val >= 0 }
              required(:workers) { |val| val.is_a?(Integer) && val.positive? }
              required(:tags) { |val| val.is_a?(Karafka::Core::Taggable::Tags) }
              required(:execution_mode) { |val| val.is_a?(String) && !val.empty? }

              nested(:listeners) do
                required(:active) { |val| val.is_a?(Integer) && val >= 0 }
                required(:standby) { |val| val.is_a?(Integer) && val >= 0 }
              end

              required(:cpu_usage) do |val|
                val.is_a?(Array) &&
                  val.all? { |key| key.is_a?(Numeric) } &&
                  val.all? { |key| key >= -1 } &&
                  val.size == 3
              end
            end

            nested(:versions) do
              required(:ruby) { |val| val.is_a?(String) && !val.empty? }
              required(:karafka) { |val| val.is_a?(String) && !val.empty? }
              required(:karafka_core) { |val| val.is_a?(String) && !val.empty? }
              required(:karafka_web) { |val| val.is_a?(String) && !val.empty? }
              required(:waterdrop) { |val| val.is_a?(String) && !val.empty? }
              required(:rdkafka) { |val| val.is_a?(String) && !val.empty? }
              required(:librdkafka) { |val| val.is_a?(String) && !val.empty? }
            end

            nested(:stats) do
              required(:busy) { |val| val.is_a?(Integer) && val >= 0 }
              required(:enqueued) { |val| val.is_a?(Integer) && val >= 0 }
              required(:waiting) { |val| val.is_a?(Integer) && val >= 0 }
              required(:utilization) { |val| val.is_a?(Numeric) && val >= 0 }

              nested(:total) do
                # There can be jobs that run without new data batches like revocation, periodic,
                # shutdown, etc. We want to track them. This is needed because in case of a
                # setup where those are significant, user may have a false sense that nothing
                # is happening in the system when no new messages are coming
                required(:jobs) { |val| val.is_a?(Integer) && val >= 0 }
                required(:batches) { |val| val.is_a?(Integer) && val >= 0 }
                required(:messages) { |val| val.is_a?(Integer) && val >= 0 }
                required(:errors) { |val| val.is_a?(Integer) && val >= 0 }
                required(:retries) { |val| val.is_a?(Integer) && val >= 0 }
                required(:dead) { |val| val.is_a?(Integer) && val >= 0 }
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
              data.fetch(:consumer_groups).each_value do |details|
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
