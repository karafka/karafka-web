# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Contracts
          # Contract for the job reporting details
          class Job < BaseContract
            configure

            required(:consumer) { |val| val.is_a?(String) }
            required(:consumer_group) { |val| val.is_a?(String) }
            required(:started_at) { |val| val.is_a?(Float) && val >= 0 }
            required(:topic) { |val| val.is_a?(String) }
            required(:partition) { |val| val.is_a?(Integer) && val >= 0 }
            required(:first_offset) { |val| val.is_a?(Integer) && val >= 0 }
            required(:last_offset) { |val| val.is_a?(Integer) && val >= 0 }
            required(:comitted_offset) { |val| val.is_a?(Integer) }
            required(:type) { |val| %w[consume revoked shutdown].include?(val) }
          end
        end
      end
    end
  end
end
