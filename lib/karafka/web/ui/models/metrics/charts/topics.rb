# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Metrics
          module Charts
            class Topics
              def initialize(data, range)
                @data = data.to_h.fetch(range)
              end

              def lags_stored
                total = Hash.new { |h, v| h[v] = 0 }

                res = @data.to_h.map do |topic, metrics|
                  metrics.each { |metric|
                    if metric.last[:lag_stored]
                      total[metric.first] ||= 0
                      total[metric.first] += metric.last[:lag_stored]
                    else
                      next if total.key?(metric.first)
                      total[metric.first] = nil
                    end
                  }

                  [
                    topic,
                    metrics.map { |metric| [metric.first, metric.last[:lag_stored]] }
                  ]
                end.to_h

                sum = { 'total' => total.map {|x, y| [x, y]} }.to_h.merge res

                sum.to_json
              end

            end
          end
        end
      end
    end
  end
end
