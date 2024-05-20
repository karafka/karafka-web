# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Namespace for metrics related models
        module Metrics
          # Materializes the aggregated data and computes the expected diffs out of the snapshots
          # We do some pre-processing to make sure, we do not have bigger gaps and to compensate
          # for reporting drifting
          class Aggregated < Lib::HashProxy
            include ::Karafka::Core::Helpers::Time

            # If samples are closer than that, sample will be rejected
            MIN_ACCEPTED_DRIFT = 4

            # If samples are further away than that, we will inject an artificial sample in-between
            MAX_ACCEPTED_DRIFT = 7

            # For which keys we should compute the delta in reference to the previous period
            # Metrics we get from the processes are always absolute, hence we need a reference point
            # to compute the deltas
            #
            # If at least two elements do not exist for given delta range, we keep it empty
            DELTA_KEYS = %i[
              jobs
              batches
              messages
              errors
              retries
              dead
            ].freeze

            private_constant :MIN_ACCEPTED_DRIFT, :MAX_ACCEPTED_DRIFT, :DELTA_KEYS

            # Builds the Web-UI historicals representation that includes deltas
            #
            # @param aggregated [Hash] aggregated historical metrics
            def initialize(aggregated)
              aggregated
                .tap { |historicals| reject_drifters(historicals) }
                .tap { |historicals| fill_gaps(historicals) }
                .then { |historicals| enrich_with_deltas(historicals) }
                .tap { |historicals| enrich_with_batch_size(historicals) }
                .tap { |historicals| enrich_with_process_rss(historicals) }
                .then { |enriched| super(enriched) }
            end

            # @return [Boolean] do we have enough data to draw any basic charts
            def sufficient?
              seconds.size > 2
            end

            private

            # Since our reporting is not ms precise, there are cases where sampling can drift.
            # If drifting gets us close to one side, for delta metrics it would create sudden
            # artificial drops in metrics that would not match the reality. We reject drifters like
            # this as we can compensate this later.
            #
            # This problems only affects our near real-time metrics with seconds precision
            #
            # @param historicals [Hash] all historicals for all the ranges
            def reject_drifters(historicals)
              initial = nil

              historicals.fetch(:seconds).delete_if do |sample|
                unless initial
                  initial = sample.first

                  next
                end

                # Reject values that are closer than minimum
                too_close = sample.first - initial < MIN_ACCEPTED_DRIFT

                initial = sample.first

                too_close
              end
            end

            # In case of a positive drift, we may have gaps bigger than few seconds in reporting.
            # This can create a false sense of spikes that do not reflect the reality. We compensate
            # this by extrapolating the delta values and using the rest as they are.
            #
            # This problems only affects our near real-time metrics with seconds precision
            #
            # @param historicals [Hash] all historicals for all the ranges
            def fill_gaps(historicals)
              filled = []
              previous = nil

              historicals.fetch(:seconds).each do |sample|
                unless previous
                  filled << sample
                  previous = sample
                  next
                end

                if sample.first - previous.first > MAX_ACCEPTED_DRIFT
                  base = sample.last.dup

                  DELTA_KEYS.each do |key|
                    base[key] = previous.last[key] + (sample.last[key] - previous.last[key]) / 2
                  end

                  filled << [previous.first + (sample.first - previous.first) / 2, base]
                end

                filled << sample
                previous = sample
              end

              historicals[:seconds] = filled
            end

            # Takes the historical hash, iterates over all the samples and enriches them with the
            # delta computed values
            #
            # @param historicals [Hash] all historicals for all the ranges
            # @return [Hash] historicals with delta based data
            def enrich_with_deltas(historicals)
              results = {}

              historicals.each do |range, time_samples|
                results[range] = []

                baseline = nil

                time_samples.each do |time_sample|
                  metrics = time_sample[1]

                  if baseline
                    deltas = compute_deltas(baseline, metrics)
                    results[range] << [time_sample[0], metrics.merge(deltas)]
                  end

                  baseline = metrics
                end
              end

              results
            end

            # Batch size is a match between number of messages and number of batches
            # It is derived out of the data we have so we compute it on the fly
            # @param historicals [Hash] all historicals for all the ranges
            def enrich_with_batch_size(historicals)
              historicals.each_value do |time_samples|
                time_samples.each do |time_sample|
                  metrics = time_sample[1]

                  batches = metrics[:batches]

                  # We check if not zero just in case something would be off there
                  # We do not want to divide by zero
                  metrics[:batch_size] = batches.zero? ? 0 : metrics[:messages] / batches
                end
              end
            end

            # Adds an average RSS on a per process basis
            # @param historicals [Hash] all historicals for all the ranges
            def enrich_with_process_rss(historicals)
              historicals.each_value do |time_samples|
                time_samples.each do |time_sample|
                  metrics = time_sample[1]

                  rss = metrics[:rss]
                  processes = metrics[:processes]

                  metrics[:process_rss] = processes.zero? ? 0 : rss / processes
                end
              end
            end

            # Computes deltas for all the relevant keys for which we want to have deltas
            #
            # @param previous [Hash]
            # @param current [Hash]
            # @return [Hash] delta computed values
            def compute_deltas(previous, current)
              DELTA_KEYS.map do |delta_key|
                [
                  delta_key,
                  current.fetch(delta_key) - previous.fetch(delta_key)
                ]
              end.to_h
            end
          end
        end
      end
    end
  end
end
