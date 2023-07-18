# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Models that wraps up the historicals and allows us to easil generate charts data
        class Charts
          # @param historicals [Hash] all historicals for all periods
          # @param period [Symbol] period that we are interested in
          def initialize(historicals, period)
            @data = historicals[period]
          end

          # @param args [Array<String>] names of historicals we want to show
          # @return [String] JSON with data about all the charts we were interested in
          def with(*args)
            args
              .map { |name| [name.to_sym, public_send(name)] }
              .to_h
              .to_json
          end

          # @return [Array<Array>] alias for `listeners_count` for nicer name
          def listeners
            public_send(:listeners_count)
          end

          # @return [Array<Array>] alias for `threads_count` for nicer name
          def threads
            public_send(:threads_count)
          end

          # @param method_name [String]
          # @param include_private [Boolean]
          def respond_to_missing?(method_name, include_private = false)
            @data.last.last.key?(method_name.to_sym)
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
