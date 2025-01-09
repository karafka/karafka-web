# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Commanding related contracts
        module Contracts
          # Makes sure, all the expected commanding config is defined as it should be
          class Config < ::Karafka::Contracts::Base
            configure do |config|
              config.error_messages = YAML.safe_load(
                File.read(
                  File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                )
              ).fetch('en').fetch('validations').fetch('config')
            end

            nested(:commanding) do
              required(:active) { |val| [true, false].include?(val) }
              required(:pause_timeout) { |val| val.is_a?(Integer) && val.positive? }
              required(:max_wait_time) { |val| val.is_a?(Integer) && val.positive? }
              required(:kafka) { |val| val.is_a?(Hash) }
            end

            # Ensure all commanding kafka keys are symbols
            virtual do |data, errors|
              next unless errors.empty?

              detected_errors = []

              data.fetch(:commanding).fetch(:kafka).each_key do |key|
                next if key.is_a?(Symbol)

                detected_errors << [[:commanding, :kafka, key], :key_must_be_a_symbol]
              end

              detected_errors
            end
          end
        end
      end
    end
  end
end
