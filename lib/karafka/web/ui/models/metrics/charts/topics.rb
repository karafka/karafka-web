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

              # @return [String] JSON with lags of each of the topics + total lag of all the topics
              #   from all the consumer groups.
              def lags_hybrid
                total = Hash.new { |h, v| h[v] = 0 }

                @data.to_h.each_value do |metrics|
                  metrics.each do |metric|
                    time = metric.first
                    lag_hybrid = metric.last[:lag_hybrid]

                    if lag_hybrid
                      total[time] ||= 0
                      total[time] += lag_hybrid
                    else
                      next if total.key?(time)

                      total[time] = nil
                    end
                  end
                end

                # Extract the lag stored only from all the data
                per_topic = @data.to_h.map do |topic, metrics|
                  extracted = metrics.map { |metric| [metric.first, metric.last[:lag_hybrid]] }

                  [topic, extracted]
                end.to_h

                # We name it with a space because someone may have a topic called "total" and we
                # want to avoid collisions
                per_topic.merge('total sum' => total.to_a).to_json
              end

              # @return [String] JSON with per-topic, highest LSO freeze duration. Useful for
              #   debugging of issues arising from hanging transactions
              def max_lso
                topics = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

                @data.to_h.each do |topic, metrics|
                  topic_without_cg = topic.split('[').first

                  metrics.each do |current|
                    ls_offset_fd = current.last[:ls_offset_fd] || 0

                    # We convert this to seconds from milliseconds due to our Web UI precision
                    # Reporting is in ms for consistency
                    normalized_fd = (ls_offset_fd / 1_000.0).round

                    topics[topic_without_cg][current.first] << normalized_fd
                  end
                end

                topics.each_value(&:compact!)
                topics.each_value { |metrics| metrics.transform_values!(&:max) }
                topics.transform_values! { |values| values.to_a.sort_by!(&:first) }
                topics.to_json
              end

              # @return [String] JSON with producers pace that represents high-watermarks sum for
              #   each topic.
              #
              # @note There is a case where data reported (sum on a topic) is lower then the
              #   previous value. This can happen around rebalances because consumer may not
              #   have all watermark offsets reported. This may cause consumers not to report some
              #   of the partitions, effectively lowering the sum. Since high-watermark offsets can
              #   only move forward, we compensate this by assuming that a lower value than
              #   previous is an artefact of that type and we replace it with the max value we had
              #   effectively compensating for under-reporting
              def pace
                topics = {}

                @data.to_h.each do |topic, metrics|
                  topic_without_cg = topic.split('[').first

                  # If we've already seen this topic data, we can skip
                  next if topics.include?(topic_without_cg)

                  max_pace = 0

                  topics[topic_without_cg] = metrics.map do |current|
                    # Pace may be empty when for a given moment in time we got no info on
                    # one of the topics. In such case we can compensate with max or 0
                    current_pace = current.last[:pace] || 0

                    max_pace = current_pace if current_pace > max_pace

                    [current.first, max_pace]
                  end
                end

                topics.each_value(&:compact!)
                topics.to_json
              end
            end
          end
        end
      end
    end
  end
end
