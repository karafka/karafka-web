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
                @data = aggregated.to_h.fetch(period)
              end

              # @param args [Array<String>] names of aggregated we want to show
              # @return [String] JSON with data about all the charts we were interested in
              def with(*args)
                args
                  .map { |name| [name.to_sym, public_send(name)] }
                  .to_h
                  .to_json
              end

              # @return [Array<Array>] alias for `listeners_count` for a nicer name
              def listeners
                public_send(:listeners_count)
              end

              # @return [Array<Array>] alias for `threads_count` for a nicer name
              def threads
                public_send(:threads_count)
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
