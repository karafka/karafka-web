# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Branding
            # Contracts for checking branding related setup
            module Contracts
              # Makes sure, all the expected UI branding config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load(
                    File.read(
                      File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                    )
                  ).fetch('en').fetch('validations').fetch('config')
                end

                nested(:ui) do
                  nested(:branding) do
                    required(:type) do |val|
                      # Type of branding style wrapping needs to align with what we support
                      # in other places
                      ::Karafka::Web::Ui::Helpers::TailwindHelper::TYPES.include?(val)
                    end

                    required(:label) do |val|
                      val == false || (val.is_a?(String) && val.size.positive?)
                    end

                    required(:notice) do |val|
                      val == false || (val.is_a?(String) && val.size.positive?)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
