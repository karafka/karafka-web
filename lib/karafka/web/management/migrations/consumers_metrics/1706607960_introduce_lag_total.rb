# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Moves to using lag total as a normalization for both lags
          class IntroduceLagTotal < Base
            self.versions_until = '1.2.0'
            self.type = :consumers_metrics

            # @param state [Hash]
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last[:lag_total] = metric.last[:lag_stored]
                  metric.last.delete(:lag_stored)
                  metric.last.delete(:lag)
                end
              end

              state[:consumer_groups].each_value do |metrics|
                metrics.each do |metric_group|
                  metric_group.last.each_value do |metric|
                    metric.each_value do |sample|
                      sample[:lag_total] = sample[:lag_stored]
                      sample.delete(:lag_stored)
                      sample.delete(:lag)
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
