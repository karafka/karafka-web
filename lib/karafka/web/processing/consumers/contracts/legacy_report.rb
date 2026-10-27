# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Contract for reports that use an older schema. We only register their process (see
          # `Processing::Consumer`), so we only need what the registration reads.
          class LegacyReport < Web::Contracts::Base
            configure

            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }

            nested(:process) do
              required(:id) { |val| val.is_a?(String) && !val.empty? }
            end
          end
        end
      end
    end
  end
end
