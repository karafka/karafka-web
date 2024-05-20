# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Moves unused "processing" that was used instead of "busy" in older versions
          class RemoveProcessing < Base
            self.versions_until = '1.1.1'
            self.type = :consumers_metrics

            # @param state [Hash]
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last.delete(:processing)
                end
              end
            end
          end
        end
      end
    end
  end
end
