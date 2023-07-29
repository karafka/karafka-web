# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Topic metrics checks
          class TopicStats < Web::Contracts::Base
            configure

            required(:lag_stored) { |val| val.is_a?(Integer) }
            required(:lag) { |val| val.is_a?(Integer) }
            required(:offset_hi) { |val| val.is_a?(Integer) }
          end
        end
      end
    end
  end
end
