# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for all tracking related contracts
      module Contracts
        # Contract for error reporting
        # Since producers and consumers report their errors to the same topic, we need to have
        # a unified contract for both
        class Error < Web::Contracts::Base
          configure

          required(:schema_version) { |val| val.is_a?(String) }
          required(:type) { |val| val.is_a?(String) && !val.empty? }
          required(:error_class) { |val| val.is_a?(String) && !val.empty? }
          required(:error_message) { |val| val.is_a?(String) }
          required(:backtrace) { |val| val.is_a?(String) }
          required(:details) { |val| val.is_a?(Hash) }
          required(:occurred_at) { |val| val.is_a?(Float) }

          nested(:process) do
            required(:id) { |val| val.is_a?(String) && !val.empty? }
            # Tags may not be present for producers because they may operate from outside of
            # karafka taggable process
            optional(:tags) { |val| val.is_a?(Karafka::Core::Taggable::Tags) }
          end
        end
      end
    end
  end
end
