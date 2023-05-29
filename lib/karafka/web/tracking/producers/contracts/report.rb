# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        module Contracts
          class Report < Tracking::Contracts::Base
            configure

            required(:schema_version) { |val| val.is_a?(String) }
            required(:id) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:type) { |val| val == 'producer' }

            nested(:process) do
              required(:started_at) { |val| val.is_a?(Numeric) && val.positive? }
              required(:name) { |val| val.is_a?(String) && val.count(':') >= 2 }
            end

            nested(:versions) do
              required(:karafka) { |val| val.is_a?(String) && !val.empty? }
              required(:waterdrop) { |val| val.is_a?(String) && !val.empty? }
              required(:ruby) { |val| val.is_a?(String) && !val.empty? }
            end

            nested(:stats) do
              required(:msg_cnt) { |val| val.is_a?(Integer) }
              required(:msg_cnt_d) { |val| val.is_a?(Integer) }
              required(:msg_size) { |val| val.is_a?(Integer) }
              required(:msg_size_d) { |val| val.is_a?(Integer) }
              required(:txmsgs) { |val| val.is_a?(Integer) }
              required(:txmsgs_d) { |val| val.is_a?(Integer) }
              required(:txmsg_bytes) { |val| val.is_a?(Integer) }
              required(:txmsg_bytes_d) { |val| val.is_a?(Integer) }
            end
          end
        end
      end
    end
  end
end
