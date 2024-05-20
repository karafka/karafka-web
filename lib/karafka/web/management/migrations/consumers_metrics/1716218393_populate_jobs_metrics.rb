# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Adds the jobs metric matching batches for aggregated metrics results
          class PopulateJobsMetrics < Base
            self.versions_until = '1.3.0'
            self.type = :consumers_metrics

            # @param state [Hash]
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last[:jobs] = metric.last[:batches] || 0
                end
              end
            end
          end
        end
      end
    end
  end
end
