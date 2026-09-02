# frozen_string_literal: true

module Karafka
  module Web
    module Contracts
      # Contract to validate Web-UI configuration
      class Config < Web::Contracts::Base
        configure

        # Use the same regexp as Karafka for topics validation
        TOPIC_REGEXP = ::Karafka::Contracts::TOPIC_REGEXP

        required(:enabled) { |val| [true, false, nil].include?(val) }
        required(:ttl) { |val| val.is_a?(Numeric) && val.positive? }
        required(:group_id) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

        nested(:topics) do
          nested(:errors) do
            required(:name) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

            required(:config) do |val|
              val.is_a?(Hash) && !val.empty? && val.keys.all?(Symbol)
            end
          end

          nested(:consumers) do
            nested(:reports) do
              required(:name) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

              required(:config) do |val|
                val.is_a?(Hash) && !val.empty? && val.keys.all?(Symbol)
              end
            end

            nested(:states) do
              required(:name) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

              required(:config) do |val|
                val.is_a?(Hash) && !val.empty? && val.keys.all?(Symbol)
              end
            end

            nested(:metrics) do
              required(:name) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

              required(:config) do |val|
                val.is_a?(Hash) && !val.empty? && val.keys.all?(Symbol)
              end
            end

            nested(:commands) do
              required(:name) { |val| val.is_a?(String) && TOPIC_REGEXP.match?(val) }

              required(:config) do |val|
                val.is_a?(Hash) && !val.empty? && val.keys.all?(Symbol)
              end
            end
          end
        end

        nested(:tracking) do
          # If set to nil, it is up to us to initialize
          required(:active) { |val| [true, false, nil].include?(val) }
          # Do not report more often then every second, this could overload the system
          required(:interval) { |val| val.is_a?(Integer) && val >= 1_000 }

          nested(:consumers) do
            required(:reporter) { |val| !val.nil? }
            required(:sampler) { |val| !val.nil? }
            required(:listeners) { |val| val.is_a?(Array) }
            required(:sync_threshold) { |val| val.is_a?(Integer) && val.positive? }
          end

          nested(:producers) do
            required(:reporter) { |val| !val.nil? }
            required(:sampler) { |val| !val.nil? }
            required(:listeners) { |val| val.is_a?(Array) }
            required(:sync_threshold) { |val| val.is_a?(Integer) && val.positive? }
          end
        end

        nested(:processing) do
          required(:active) { |val| [true, false].include?(val) }
          # Do not update data more often not to overload and not to generate too much data
          required(:interval) { |val| val.is_a?(Integer) && val >= 1_000 }

          # Extra Kafka setup for our processing consumer
          required(:kafka) { |val| val.is_a?(Hash) }
        end

        nested(:ui) do
          nested(:sessions) do
            required(:key) { |val| val.is_a?(String) && !val.empty? }
            required(:env_key) { |val| val.is_a?(String) && !val.empty? }
            required(:secret) { |val| val.is_a?(String) && val.length >= 64 }
          end

          required(:per_page) { |val| val.is_a?(Integer) && val >= 1 && val <= 100 }
          required(:max_visible_payload_size) { |val| val.is_a?(Integer) && val >= 1 }
          required(:kafka) { |val| val.is_a?(Hash) }

          nested(:custom) do
            required(:css) { |val| val == false || (val.is_a?(String) && !val.empty?) }
            required(:js) { |val| val == false || (val.is_a?(String) && !val.empty?) }
            required(:nav_erb) { |val| val == false || (val.is_a?(String) && !val.empty?) }
          end

          required(:dlq_patterns) do |val|
            val.is_a?(Array) &&
              val.all? { |attr| attr.is_a?(String) || attr.is_a?(Regexp) }
          end

          nested(:visibility) do
            required(:internal_topics) { |val| [true, false].include?(val) }
            required(:active_topics_cluster_lags_only) { |val| [true, false].include?(val) }
          end
        end
      end
    end
  end
end
