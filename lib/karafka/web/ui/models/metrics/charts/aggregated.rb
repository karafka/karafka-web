# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        module Metrics
          # Namespace for models related to presentation of charts
          module Charts
            # Model for formatting aggregated metrics data for charts
            class Aggregated < Lib::HashProxy
              # @param aggregated [Hash] all aggregated for all periods
              # @param period [Symbol] period that we are interested in
              def initialize(aggregated, period)
                @period = period
                @data = aggregated.to_h.fetch(period)
              end

              # @return [String] JSON with bytes sent and bytes received metrics
              def data_transfers
                scale_factor = Processing::TimeSeriesTracker::TIME_RANGES
                               .fetch(@period)
                               .fetch(:resolution)
                               .then { |factor| factor / 1_024.to_f }

                received = bytes_received.map do |element|
                  [element[0], element[1] * scale_factor]
                end

                sent = bytes_sent.map do |element|
                  [element[0], element[1] * scale_factor]
                end

                { received: received, sent: sent }.to_json
              end

              # @param args [Array<String>] names of aggregated we want to show
              # @return [String] JSON with data about all the charts we were interested in
              def with(*args)
                args
                  .map { |name| [name.to_sym, public_send(name)] }
                  .to_h
                  .to_json
              end

              # @return [Array<Array<Symbol, Integer>>] active listeners statistics
              def active_listeners
                listeners.map do |listener|
                  [listener[0], listener[1].fetch(:active)]
                end
              end

              # @return [Array<Array<Symbol, Integer>>] standby listeners statistics
              def standby_listeners
                listeners.map do |listener|
                  [listener[0], listener[1].fetch(:standby)]
                end
              end

              # @param method_name [String]
              # @param include_private [Boolean]
              def respond_to_missing?(method_name, include_private = false)
                @data.last.last.key?(method_name.to_sym) || super
              end

              # Handles delegation to fetch appropriate historical metrics based on their name
              #
              # @param method_name [String]
              # @param arguments [Array] missing method call arguments
              def method_missing(method_name, *arguments)
                if @data.last.last.key?(method_name.to_sym)
                  @data.map { |a| [a.first, a.last[method_name]] }
                else
                  super
                end
              end
            end
          end
        end
      end
    end
  end
end
