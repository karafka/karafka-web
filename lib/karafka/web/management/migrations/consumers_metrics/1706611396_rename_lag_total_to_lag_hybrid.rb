# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Renames total lag to hybrid to better represent what it is
          class RenameLagTotalToLagHybrid < Base
            self.versions_until = '1.2.1'
            self.type = :consumers_metrics

            # @param state [Hash]
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last[:lag_hybrid] = metric.last[:lag_total] || 0
                  metric.last.delete(:lag_total)
                end
              end

              state[:consumer_groups].each_value do |metrics|
                metrics.each do |metric_group|
                  metric_group.last.each_value do |metric|
                    metric.each_value do |sample|
                      sample[:lag_hybrid] = sample[:lag_total]
                      sample.delete(:lag_total)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
