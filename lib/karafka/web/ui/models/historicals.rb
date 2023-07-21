# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Materializes the historical data and computes the expected diffs out of the snapshots
        # We do some pre-processing to make sure, we do not have bigger gaps and to compensate
        # for reporting drifting
        class Historicals < Lib::HashProxy
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
            batches
            messages
            errors
            retries
            dead
          ].freeze

          private_constant :MIN_ACCEPTED_DRIFT, :MAX_ACCEPTED_DRIFT, :DELTA_KEYS

          # Builds the Web-UI historicals representation that includes deltas
          #
          # @param state [Hash]
          def initialize(state)
            stats = state.to_h.fetch(:stats)
            dispathed_at = state.to_h.fetch(:dispatched_at)

            state
              .to_h
              .fetch(:historicals)
              .tap { |historicals| reject_drifters(historicals) }
              .tap { |historicals| fill_gaps(historicals) }
              .tap { |historicals| inject_current_stats(historicals, stats, dispathed_at) }
              .then { |historicals| enrich_with_deltas(historicals) }
              .tap { |historicals| enrich_with_batch_size(historicals) }
              .tap { |historicals| enrich_with_process_rss(historicals) }
              .then { |enriched| super(enriched) }
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

            historicals[:seconds].delete_if do |sample|
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
          # this by extrapolating the values.
          #
          # This problems only affects our near real-time metrics with seconds precision
          #
          # @param historicals [Hash] all historicals for all the ranges
          def fill_gaps(historicals)
            filled = []
            previous = nil

            historicals[:seconds].each do |sample|
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

          # Injects the most recent current stats that is take from the state except the errors
          #
          # @param historicals [Hash] all historicals for all the ranges
          # @param stats [Hash] current stats
          # @param dispatched_at [Float] time of the current state dispatch
          #
          # @note The current state `error` key is a sum of processing errors and consuming errors
          #   while on the charts we want to show only consuming errors as this value should
          #   correspond with messages and batches. Because of that we cannot use this value and
          #   we replace it with previous historical sample "consumer only" errors that are based
          #   on the counter we keep.
          def inject_current_stats(historicals, stats, dispatched_at)
            historicals.each_value do |time_samples|
              errors = time_samples.last.last[:errors]

              time_samples << [dispatched_at.to_i, stats.merge(errors: errors)]
            end
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
