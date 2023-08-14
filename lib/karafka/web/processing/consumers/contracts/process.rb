# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # State process details contract
          class Process < Web::Contracts::Base
            configure

            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:offset) { |val| val.is_a?(Integer) && val >= 0 }
          end
        end
      end
    end
  end
end
