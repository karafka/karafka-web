# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Topic metrics checks
          class TopicStats < Web::Contracts::Base
            configure

            required(:lag_hybrid) { |val| val.is_a?(Integer) }
            required(:pace) { |val| val.is_a?(Integer) }
            required(:ls_offset_fd) { |val| val.is_a?(Integer) && val >= 0 }
          end
        end
      end
    end
  end
end
