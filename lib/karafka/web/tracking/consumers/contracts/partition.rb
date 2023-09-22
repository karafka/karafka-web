# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Partition metrics required for web to operate
          class Partition < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(Integer) && val >= 0 }
            required(:lag) { |val| val.is_a?(Integer) }
            required(:lag_d) { |val| val.is_a?(Integer) }
            required(:lag_stored) { |val| val.is_a?(Integer) }
            required(:lag_stored_d) { |val| val.is_a?(Integer) }
            required(:committed_offset) { |val| val.is_a?(Integer) }
            required(:committed_offset_fd) { |val| val.is_a?(Integer) && val >= 0 }
            required(:stored_offset) { |val| val.is_a?(Integer) }
            required(:stored_offset_fd) { |val| val.is_a?(Integer) && val >= 0 }
            required(:fetch_state) { |val| val.is_a?(String) && !val.empty? }
            required(:poll_state) { |val| val.is_a?(String) && !val.empty? }
            required(:poll_state_ch) { |val| val.is_a?(Integer) && val >= 0 }
            required(:hi_offset) { |val| val.is_a?(Integer) }
            required(:hi_offset_fd) { |val| val.is_a?(Integer) && val >= 0 }
            required(:lo_offset) { |val| val.is_a?(Integer) }
            required(:eof_offset) { |val| val.is_a?(Integer) }
            required(:ls_offset) { |val| val.is_a?(Integer) }
            required(:ls_offset_d) { |val| val.is_a?(Integer) }
            required(:ls_offset_fd) { |val| val.is_a?(Integer) && val >= 0 }
          end
        end
      end
    end
  end
end
