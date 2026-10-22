# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Contract used to validate consumers reports when we ingest them.
          #
          # Reports may come from processes that do not run the Ruby tracking (for example apps
          # on librdkafka bindings in other languages), so unlike the sender side
          # `Tracking::Consumers::Contracts::Report`, it does not check Ruby-only values (Ruby
          # classes, Karafka status names). It requires the process, versions and stats fields and
          # the consumer groups tree and jobs keys that the processing and the Web UI read.
          class Report < Web::Contracts::Base
            configure

            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:type) { |val| val == "consumer" }

            nested(:process) do
              required(:started_at) { |val| val.is_a?(Numeric) && val.positive? }
              required(:id) { |val| val.is_a?(String) && !val.empty? }
              required(:cpus) { |val| val.is_a?(Integer) && val >= 1 }
              required(:memory_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_total_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_size) { |val| val.is_a?(Integer) && val >= 0 }
              required(:status) { |val| val.is_a?(String) && !val.empty? }
              required(:threads) { |val| val.is_a?(Integer) && val >= 0 }
              required(:workers) { |val| val.is_a?(Integer) && val >= 0 }
              required(:tags) { |val| val.is_a?(Array) && val.all?(String) }
              required(:execution_mode) { |val| val.is_a?(String) && !val.empty? }

              nested(:listeners) do
                required(:active) { |val| val.is_a?(Integer) && val >= 0 }
                required(:standby) { |val| val.is_a?(Integer) && val >= 0 }
              end

              required(:cpu_usage) do |val|
                val.is_a?(Array) && val.size == 3 && val.all?(Numeric)
              end
            end

            nested(:versions) do
              required(:ruby) { |val| val.is_a?(String) }
              required(:karafka) { |val| val.is_a?(String) }
              required(:karafka_core) { |val| val.is_a?(String) }
              required(:karafka_web) { |val| val.is_a?(String) }
              required(:waterdrop) { |val| val.is_a?(String) }
              required(:rdkafka) { |val| val.is_a?(String) }
              required(:librdkafka) { |val| val.is_a?(String) }
            end

            nested(:stats) do
              required(:busy) { |val| val.is_a?(Integer) && val >= 0 }
              required(:enqueued) { |val| val.is_a?(Integer) && val >= 0 }
              required(:waiting) { |val| val.is_a?(Integer) && val >= 0 }
              required(:utilization) { |val| val.is_a?(Numeric) && val >= 0 }

              nested(:total) do
                required(:jobs) { |val| val.is_a?(Integer) && val >= 0 }
                required(:batches) { |val| val.is_a?(Integer) && val >= 0 }
                required(:messages) { |val| val.is_a?(Integer) && val >= 0 }
                required(:errors) { |val| val.is_a?(Integer) && val >= 0 }
                required(:retries) { |val| val.is_a?(Integer) && val >= 0 }
                required(:dead) { |val| val.is_a?(Integer) && val >= 0 }
              end
            end

            required(:consumer_groups) { |val| val.is_a?(Hash) && val.values.all?(Hash) }
            required(:jobs) { |val| val.is_a?(Array) && val.all?(Hash) }

            # Validates the consumer groups tree down to the partitions. Without these keys the UI
            # fails or `HashProxy` renders a same-named nested value instead.
            virtual do |data, errors|
              next unless errors.empty?

              consumer_group_contract = ConsumerGroup.new

              data.fetch(:consumer_groups).flat_map do |cg_id, details|
                consumer_group_contract.call(details).errors.map do |path, message|
                  [[:consumer_groups, cg_id, path], message]
                end
              end
            end

            # Validates the jobs keys the jobs views read
            virtual do |data, errors|
              next unless errors.empty?

              job_contract = Job.new

              data.fetch(:jobs).each_with_index.flat_map do |details, index|
                job_contract.call(details).errors.map do |path, message|
                  [[:jobs, index, path], message]
                end
              end
            end
          end
        end
      end
    end
  end
end
