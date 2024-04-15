# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
