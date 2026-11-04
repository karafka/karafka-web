# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Ingest expectations for each partition of a topic
          class Partition < Web::Contracts::Base
            configure

            required(:id) { |val| val.is_a?(Integer) }
            required(:lag) { |val| val.is_a?(Integer) }
            required(:lag_d) { |val| val.is_a?(Integer) }
            required(:lag_stored) { |val| val.is_a?(Integer) }
            required(:lag_stored_d) { |val| val.is_a?(Integer) }
            required(:committed_offset) { |val| val.is_a?(Integer) }
            required(:stored_offset) { |val| val.is_a?(Integer) }
            required(:hi_offset) { |val| val.is_a?(Integer) }
            required(:ls_offset) { |val| val.is_a?(Integer) }
            required(:ls_offset_fd) { |val| val.is_a?(Integer) }
            required(:poll_state_ch) { |val| val.is_a?(Integer) }

            required(:fetch_state) { |val| val.is_a?(String) }
            required(:poll_state) { |val| val.is_a?(String) }
          end
        end
      end
    end
  end
end
