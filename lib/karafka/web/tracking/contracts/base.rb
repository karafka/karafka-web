# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for contracts used by consumers and producers tracking
      module Contracts
        # Base for all the metric related contracts
        class Base < ::Karafka::Core::Contractable::Contract
          class << self
            # This layer is not for users extensive feedback, thus we can easily use the minimum
            # error messaging there is.
            def configure
              super do |config|
                config.error_messages = YAML.safe_load(
                  File.read(
                    File.join(Karafka::Web.gem_root, 'config', 'locales', 'errors.yml')
                  )
                ).fetch('en').fetch('validations').fetch('web')
              end
            end
          end

          # @param data [Hash] data for validation
          # @return [Boolean] true if all good
          # @raise [Errors::ContractError] invalid report
          def validate!(data)
            super(data, Errors::Tracking::ContractError)
          end
        end
      end
    end
  end
end
