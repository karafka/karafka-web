# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Manages the historical metrics aggregations
        #
        # We aggregate for last:
        #   - 7 days (every day)
        #   - 24 hours (every hour)
        #   - 1 hour (every minute) + the most recent as an update every time (leading)
        #
        # @note Please note we publish always **absolute** metrics and not deltas in reference to
        #   a given time window. This needs to be computed in the frontend as we want to have
        #   state facts in the storage.
        class Historicals
          include ::Karafka::Core::Helpers::Time

          # How many samples and in what resolution should we track for given time range
          # @note We add one more than we want to display for delta computation when ranges
          # are full
          TIME_RANGES = {
            # 7 days sampling
            days: {
              # Sample every 8 hours so we end up with 56 samples over a week + 1 for baseline
              resolution: 8 * 60 * 60,
              limit: 57
            }.freeze,
            # 24 hours sampling
            hours: {
              # Every 30 minutes for 24 hours + baseline
              resolution: 30 * 60,
              limit: 49
            }.freeze,
            # 60 minutes sampling
            minutes: {
              # Every one minute for an hour => 60 samples
              resolution: 60,
              limit: 61
            }.freeze,
            # 5 minutes sampling
            seconds: {
              # Every 5 seconds with 60 samples + baseline. That is 300 seconds => 5 minutes
              resolution: 5,
              limit: 61
            }.freeze
          }.freeze

          # @param aggregated_state [Hash] full aggregated state without historicals
          def initialize(aggregated_state)
            # Builds an empty structure for potential time ranges we are interested in
            @historicals = TIME_RANGES.keys.map { |name| [name, []] }.to_h

            # Fetch the existing (if any) historical values that we already have
            import_existing(aggregated_state)

            # Build the current historical aggregation that we will use as the most recent time
            # point
            point_in_time = aggregated_state.fetch(:stats).dup

            # Inject the time point into all the historicals
            inject(point_in_time)

            # Inject this point in time into the stats
            # Evict elements that are beyond our time and resolution
            evict
          end

          # @return [Hash] aggregated historicals hash
          def to_h
            @historicals
          end

          private

          # Import existing previous historical metrics as they are
          #
          # @param aggregated_state [Hash]
          def import_existing(aggregated_state)
            aggregated_state.fetch(:historicals, {}).each do |range_name, values|
              @historicals[range_name] = values
            end
          end

          # Injects the current most recent stats sample into each of the time ranges on which we
          # operate. This allows us on all the charts to present the most recent value before a
          # given time window is completed
          #
          # @param point_in_time [Hash] current stats
          def inject(point_in_time)
            now = float_now.to_i

            @historicals.each_value do |points|
              points << [now, point_in_time]
            end
          end

          # Removes historical metrics that are beyond our expected range, so we maintain a stable
          # count and not overload the states topic with extensive data.
          def evict
            # Evict old metrics that are beyond our aggregated range
            # Builds a sliding window that goes backwards
            @historicals.each do |range_name, values|
              rules = TIME_RANGES.fetch(range_name)
              limit = rules.fetch(:limit)
              resolution = rules.fetch(:resolution)

              grouped = values.group_by { |sample| sample.first / resolution }
              times = grouped.values.map(&:first)
              times.uniq!(&:first)
              # Squash in case there would be two events from the same time
              times.sort_by!(&:first)

              @historicals[range_name] = times.last(limit)
            end
          end
        end
      end
    end
  end
end
