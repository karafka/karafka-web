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
          # classes, Karafka status names). It requires the process, versions and stats fields
          # that the processing and the Web UI read. Consumer groups and jobs are checked only
          # for their top-level shape.
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
          end
        end
      end
    end
  end
end
