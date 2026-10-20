# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Relaxed contract used to validate consumers reports when we ingest them.
          #
          # Reports may come from processes that do not run the Ruby tracking (for example apps
          # on librdkafka bindings in other languages), so unlike the sender side
          # `Tracking::Consumers::Contracts::Report`, it checks only what the processing and the
          # Web UI need to materialize and render a report.
          class Report < Web::Contracts::Base
            configure

            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:type) { |val| val == "consumer" }
            required(:versions) { |val| val.is_a?(Hash) }
            required(:stats) { |val| val.is_a?(Hash) }
            required(:consumer_groups) { |val| val.is_a?(Hash) }
            required(:jobs) { |val| val.is_a?(Array) }

            nested(:process) do
              required(:id) { |val| val.is_a?(String) && !val.empty? }
              required(:status) { |val| val.is_a?(String) && !val.empty? }
            end
          end
        end
      end
    end
  end
end
