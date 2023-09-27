# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Allows us to accumulate and track time series data with given resolution
      #
      # We aggregate for last:
      #   - 7 days (every day)
      #   - 24 hours (every hour)
      #   - 1 hour (every minute) + the most recent as an update every time (leading)
      #
      # @note Please note we publish always **absolute** metrics and not deltas in reference to
      #   a given time window. This needs to be computed in the frontend as we want to have
      #   state facts in the storage.
      #
      # @note Please note we evict and cleanup data only before we want to use it. This will put
      #   more stress on memory but makes this tracker 70-90% faster. Since by default we anyhow
      #   sample every few seconds, this trade-off makes sense.
      class TimeSeriesTracker
        include ::Karafka::Core::Helpers::Time

        # How many samples and in what resolution should we track for given time range
        # @note We add one more than we want to display for delta computation when ranges
        # are full in the UI
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

        # @param existing [Hash] existing historical metrics (may be empty for the first state)
        def initialize(existing)
          # Builds an empty structure for potential time ranges we are interested in
          @historicals = TIME_RANGES.keys.map { |name| [name, []] }.to_h

          # Fetch the existing (if any) historical values that we already have
          import_existing(existing)
        end

        # Adds current state into the states for tracking
        # @param current [Hash] hash with current state
        # @param state_time [Float] float UTC time from which the state comes
        def add(current, state_time)
          # Inject the time point into all the historicals
          inject(current, state_time)
        end

        # Evicts expired and duplicated series and returns the cleaned hash
        # @return [Hash] aggregated historicals hash
        def to_h
          evict

          @historicals
        end

        private

        # Import existing previous historical metrics as they are
        #
        # @param existing [Hash] existing historical metrics
        def import_existing(existing)
          existing.each do |range_name, values|
            @historicals[range_name] = values
          end
        end

        # Injects the current most recent stats sample into each of the time ranges on which we
        # operate. This allows us on all the charts to present the most recent value before a
        # given time window is completed
        #
        # @param current [Hash] current stats
        # @param state_time [Float] time from which this state comes
        def inject(current, state_time)
          @historicals.each_value do |points|
            points << [state_time.floor, current]
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

            # Inject the most recent to always have it in each reporting range
            # Otherwise for a longer time ranges we would not have the most recent state
            # available
            times << values.last unless values.empty?

            # Keep the most recent state out of many that would come from the same time moment
            # Squash in case there would be two events from the same time
            times.reverse!
            times.uniq!(&:first)
            times.reverse!

            times.sort_by!(&:first)

            @historicals[range_name] = times.last(limit)
          end
        end
      end
    end
  end
end
