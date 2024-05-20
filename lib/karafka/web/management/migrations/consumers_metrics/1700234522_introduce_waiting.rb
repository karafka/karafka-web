# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersMetrics
          # Introduce waiting in consumers metrics to complement busy and enqueued for jobs metrics
          class IntroduceWaiting < Base
            self.versions_until = '1.1.1'
            self.type = :consumers_metrics

            # @param state [Hash]
            def migrate(state)
              state[:aggregated].each_value do |metrics|
                metrics.each do |metric|
                  metric.last[:waiting] = 0
                end
              end
            end
          end
        end
      end
    end
  end
end
