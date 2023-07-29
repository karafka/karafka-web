# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Metrics
          module Charts
            # Model for preparing data about topics states
            class Topics
              # @param topics_data [Hash] topics aggregated metrics data
              # @param period [Symbol] period that we are interested in
              def initialize(topics_data, period)
                @data = topics_data.to_h.fetch(period)
              end

              def lags_stored
                total = Hash.new { |h, v| h[v] = 0 }

                res = @data.to_h.map do |topic, metrics|
                  metrics.each do |metric|
                    if metric.last[:lag_stored]
                      total[metric.first] ||= 0
                      total[metric.first] += metric.last[:lag_stored]
                    else
                      next if total.key?(metric.first)

                      total[metric.first] = nil
                    end
                  end

                  [
                    topic,
                    metrics.map { |metric| [metric.first, metric.last[:lag_stored]] }
                  ]
                end.to_h

                sum = { 'total' => total.map {|x, y| [x, y]} }.to_h.merge res

                sum.to_json
              end

              def produced
                res = @data.to_h.map do |topic, metrics|
                  previous = nil
                  [
                    topic,
                    metrics.map do |metric|
                      unless previous
                        previous = metric
                        next
                      end

                      current = metric.last[:offset_hi]

                      if previous.last[:offset_hi].nil? || current.nil?
                        r = [metric.first, 0]
                      else
                        r = [metric.first, current - previous.last[:offset_hi]]
                      end

                      previous = metric

                      r
                    end.compact
                  ]
                end.compact.to_h

                res.to_json
              end
            end
          end
        end
      end
    end
  end
end
