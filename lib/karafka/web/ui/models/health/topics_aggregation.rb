# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Collapses the report-based per-partition tree from {Health.current} into a single
          # {AggregatedTopic} summary per topic, for the per-topic health view where each topic is a
          # single row. The consumer group level (including `:rebalanced_at`) and the
          # `cg => :topics => topic_name` shape are preserved, so the existing sorting and filtering
          # flows keep working unchanged.
          class TopicsAggregation
            class << self
              # @param state [State] current system state
              # @return [Hash] hash with per-topic aggregated statistics
              def call(state)
                stats = Health.current(state)

                stats.each_value do |cg_details|
                  cg_details[:topics].each do |topic_name, topic_details|
                    cg_details[:topics][topic_name] = AggregatedTopic.new(topic_name, topic_details)
                  end
                end

                stats
              end
            end
          end
        end
      end
    end
  end
end
