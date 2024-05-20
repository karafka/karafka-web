# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Consumer tracking related contracts
        module Contracts
          # Contract used to validate the stats that are both present in state and metrics
          class AggregatedStats < Web::Contracts::Base
            configure

            required(:batches) { |val| val.is_a?(Integer) && val >= 0 }
            required(:jobs) { |val| val.is_a?(Integer) && val >= 0 }
            required(:messages) { |val| val.is_a?(Integer) && val >= 0 }
            required(:retries) { |val| val.is_a?(Integer) && val >= 0 }
            required(:dead) { |val| val.is_a?(Integer) && val >= 0 }
            required(:errors) { |val| val.is_a?(Integer) && val >= 0 }
            required(:busy) { |val| val.is_a?(Integer) && val >= 0 }
            required(:enqueued) { |val| val.is_a?(Integer) && val >= 0 }
            required(:workers) { |val| val.is_a?(Integer) && val >= 0 }
            required(:processes) { |val| val.is_a?(Integer) && val >= 0 }
            required(:rss) { |val| val.is_a?(Numeric) && val >= 0 }
            required(:utilization) { |val| val.is_a?(Numeric) && val >= 0 }
            required(:lag_hybrid) { |val| val.is_a?(Integer) }

            nested(:listeners) do
              required(:active) { |val| val.is_a?(Integer) && val >= 0 }
              required(:standby) { |val| val.is_a?(Integer) && val >= 0 }
            end
          end
        end
      end
    end
  end
end
