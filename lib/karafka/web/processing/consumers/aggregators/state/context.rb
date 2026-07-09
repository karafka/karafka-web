# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            # Shared, per-call value object passed through the `State` pipeline steps.
            #
            # Each step reads and mutates the contents of `state`/`active_reports` in place to
            # enrich the materialized state for the next step, instead of each step reaching
            # into `State`'s own ivars directly. This keeps steps isolated and independently
            # testable with a hand-built `Context`.
            class Context
              # Initialize all instance variables upfront so every instance has the same
              # object shape, avoiding Ruby's `:performance` "shape variations" warning.
              #
              # @param state [Hash] current materialized state (mutated in place by steps)
              # @param active_reports [Hash] process reports memoized by the aggregator
              # @param aggregated_from [Float] time from which this aggregation run comes
              # @param report [Hash] the incoming consumer process state report
              # @param offset [Integer] offset of the message with the state report
              def initialize(state:, active_reports:, aggregated_from:, report:, offset:)
                @state = state
                @active_reports = active_reports
                @aggregated_from = aggregated_from
                @report = report
                @offset = offset
              end

              attr_reader :state, :active_reports, :aggregated_from, :report, :offset
            end
          end
        end
      end
    end
  end
end
