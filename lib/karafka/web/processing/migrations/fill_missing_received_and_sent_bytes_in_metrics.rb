# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Migrations
        class FillMissingReceivedAndSentBytesInMetrics < Base
          self.created_at = 1699543515
          self.versions_until = '1.1.0'
          self.type = :consumers_metrics

          def migrate(state)
            state[:aggregated].each_value do |metrics|
              metrics.each do |metric|
                metric.last[:bytes_sent] = 0
                metric.last[:bytes_received] = 0
              end
            end

            state
          end
        end
      end
    end
  end
end
