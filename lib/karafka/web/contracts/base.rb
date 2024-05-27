# frozen_string_literal: true

module Karafka
  module Web
    # Namespace for contracts across the web
    module Contracts
      # Base for all the contracts
      class Base < ::Karafka::Core::Contractable::Contract
        class << self
          # This layer is not for users extensive feedback, thus we can easily use the minimum
          # error messaging there is.
          def configure
            return super if block_given?

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
          super(data, Errors::ContractError)
        end
      end
    end
  end
end
