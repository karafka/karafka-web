# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Partition metrics required for web to operate
          class Partition < BaseContract
            configure

            required(:id) { |val| val.is_a?(Integer) && val >= 0 }
            required(:lag_stored) { |val| val.is_a?(Integer) }
            required(:lag_stored_d) { |val| val.is_a?(Integer) }
            required(:committed_offset) { |val| val.is_a?(Integer) }
            required(:stored_offset) { |val| val.is_a?(Integer) }
          end
        end
      end
    end
  end
end
