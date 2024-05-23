# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            class Contract < Web::Contracts::Base
              configure

              required(:phrase) { |val| val.is_a?(String) && !val.empty? }
              required(:messages) { |val| val.is_a?(Integer) && val >= 1 && val <= 100_000 }
              required(:strategy) { |val| val.is_a?(String) && !val.empty? }
              required(:offset_type) { |val| %w[latest offset timestamp].include?(val) }
              required(:offset) { |val| val.is_a?(Integer) && val >= 0 }

              required(:timestamp) do |val|
                next false unless val.is_a?(Integer)
                next false if val < 0
                next false if val > ((Time.now.to_f + 60) * 1_000).to_i

                true
              end

              required(:partitions) do |val|
                next false unless val.is_a?(Array)
                next false if val.empty?

                val.all? { |ar_val| ar_val.is_a?(String) }
              end
            end
          end
        end
      end
    end
  end
end
