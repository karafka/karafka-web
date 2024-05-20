# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Adds bytes_sent and bytes_received to all the aggregated metrics samples, so we have
          # charts that do not have to fill gaps or check anything
          class FillMissingReceivedAndSentBytes < Base
            self.versions_until = '1.1.0'
            self.type = :consumers_metrics

            # @param state [Hash] metrics state
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last[:bytes_sent] = 0
                  metric.last[:bytes_received] = 0
                end
              end
            end
          end
        end
      end
    end
  end
end
