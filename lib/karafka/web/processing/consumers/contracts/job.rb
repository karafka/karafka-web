# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Ingest expectations for each job of a report
          class Job < Web::Contracts::Base
            configure

            required(:consumer) { |val| val.is_a?(String) }
            required(:consumer_group) { |val| val.is_a?(String) }
            required(:topic) { |val| val.is_a?(String) }
            required(:partition) { |val| val.is_a?(Integer) }
            required(:first_offset) { |val| val.is_a?(Integer) }
            required(:updated_at) { |val| val.is_a?(Numeric) }
            required(:status) { |val| val.is_a?(String) }
          end
        end
      end
    end
  end
end
