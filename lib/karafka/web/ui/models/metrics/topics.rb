# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Metrics
          # Representation of topics historical metrics based on the aggregated metrics data
          # We do some pre-processing to align and normalize all the data
          class Topics < Lib::HashProxy
            # @param consumers_groups [Hash] historical metrics for consumers groups
            def initialize(consumers_groups)
              aggregate_topics_data(consumers_groups)
                .tap { |topics_metrics| nulify_gaps(topics_metrics) }
                .then { |topics_metrics| super(topics_metrics) }
            end

            private

            # Extracts and aggregates data on a per-topic basis in a hash. Because in theory same
            # topic can be consumed by multiple consumer groups, we include consumer group in the
            # hash keys.
            #
            # @param consumers_groups [Hash] consumers groups initial hash with metrics
            # @return [Hash] remapped hash with range including extracted topics details
            def aggregate_topics_data(consumers_groups)
              extracted = Hash.new { |h, k| h[k] = [] }

              consumers_groups.each do |range, samples|
                range_extracted = {}

                samples.each do |sample|
                  time = sample.first
                  groups = sample.last

                  groups.each do |cg_name, topics|
                    topics.each do |topic_name, topic_data|
                      range_extracted["#{topic_name}[#{cg_name}]"] ||= []
                      range_extracted["#{topic_name}[#{cg_name}]"] << [time, topic_data]
                    end
                  end
                end

                # Always align the order of topics in hash based on their name so it is
                # independent from the reported order
                extracted[range] = range_extracted.keys.sort.map do |key|
                  [key, range_extracted[key]]
                end.to_h
              end

              extracted
            end

            # Nullifies gaps within data with metrics with nil values. This is needed for us to be
            # able to provide consistent charts even with gaps in reporting.
            #
            # @param topics_metrics [Hash] flattened topics data
            # @note This modifies the original data in place
            # @note We nullify both gaps in metrics as well as gaps in times (no values for time)
            def nulify_gaps(topics_metrics)
              # Hash with all potential keys that a single sample metric can have
              # This allows us to fill gaps not only in times but also in values
              base_samples = topics_metrics
                             .values
                             .map(&:values)
                             .flatten
                             .select { |val| val.is_a?(Hash) }
                             .flat_map(&:keys)
                             .uniq
                             .map { |key| [key, nil] }
                             .to_h
                             .freeze

              # Normalize data in between topics reportings
              # One topic may have a sample in a time moment when a different one does not
              topics_metrics.each_value do |samples|
                # All available times from all the topics
                times = samples.values.map { |set| set.map(&:first) }.flatten.uniq

                samples.each_value do |set|
                  times.each do |time|
                    existing_index = set.find_index { |existing_time, _| existing_time == time }

                    if existing_index
                      existing_value = set[existing_index][1]
                      set[existing_index][1] = base_samples.merge(existing_value)
                    else
                      set << [time, base_samples]
                    end
                  end

                  set.sort_by!(&:first)
                end
              end
            end
          end
        end
      end
    end
  end
end
