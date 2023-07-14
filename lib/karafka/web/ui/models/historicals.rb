# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Materializes the historical data and computes the expected diffs out of the snapshots
        class Historicals < Lib::HashProxy
          include ::Karafka::Core::Helpers::Time

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

          # Builds the Web-UI historicals representation that includes deltas
          #
          # @param state [Hash]
          def initialize(state)
            stats = state.to_h.fetch(:stats)
            dispathed_at = state.to_h.fetch(:dispatched_at)

            state
              .to_h
              .fetch(:historicals)
              .tap { |historicals| inject_current_stats(historicals, stats, dispathed_at) }
              .then { |historicals| enrich_with_deltas(historicals) }
              .tap { |historicals| enrich_with_batch_size(historicals) }
              .tap { |historicals| enrich_with_process_rss(historicals) }
              .then { |enriched| super(enriched) }
          end

          private

          # Injects the most recent current stats that is take from the state except the errors
          #
          # @param
          # @param
          # @param
          #
          # @note The current state `error` key is a sum of processing errors and consuming errors
          #   while on the charts we want to show only consuming errors as this value should
          #   correspond with messages and batches. Because of that we cannot use this value and
          #   we replace it with previous historical sample "consumer only" errors that are based
          #   on the counter we keep.
          def inject_current_stats(historicals, stats, dispathed_at)
            historicals.each_value do |time_samples|
              errors = time_samples.last.last[:errors]

              time_samples << [dispathed_at.to_i, stats.merge(errors: errors)]
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
            historicals.each do |range, time_samples|
              time_samples.each do |time_sample|
                metrics = time_sample[1]

                batches = metrics[:batches]

                # We check if not zero just in case something would be off there
                # We do not want to divide by zero
                metrics[:batch_size] = batches.zero? ? 0 : metrics[:messages] / batches.to_f
              end
            end
          end

          def enrich_with_process_rss(historicals)
            historicals.each do |range, time_samples|
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
