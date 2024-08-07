# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Contract for the job reporting details
          class Job < Web::Contracts::Base
            configure

            required(:consumer) { |val| val.is_a?(String) }
            required(:consumer_group) { |val| val.is_a?(String) }
            required(:updated_at) { |val| val.is_a?(Float) && val >= 0 }
            required(:topic) { |val| val.is_a?(String) }
            required(:partition) { |val| val.is_a?(Integer) && val >= 0 }
            required(:first_offset) { |val| val.is_a?(Integer) && (val >= 0 || val == -1001) }
            required(:last_offset) { |val| val.is_a?(Integer) && (val >= 0 || val == -1001) }
            required(:committed_offset) { |val| val.is_a?(Integer) }
            required(:messages) { |val| val.is_a?(Integer) && val >= 0 }
            required(:type) { |val| %w[consume revoked shutdown tick eofed].include?(val) }
            required(:tags) { |val| val.is_a?(Karafka::Core::Taggable::Tags) }
            # -1 can be here for workless flows
            required(:consumption_lag) { |val| val.is_a?(Integer) && (val >= 0 || val == -1) }
            required(:processing_lag) { |val| val.is_a?(Integer) && (val >= 0 || val == -1) }
            required(:status) { |val| %w[running pending].include?(val) }
          end
        end
      end
    end
  end
end
