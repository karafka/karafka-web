# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          # Policies related contracts
          module Policies
            # Namespace with policies related contracts
            module Contracts
              # Makes sure, all the expected UI policies config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                  ).fetch('en').fetch('validations').fetch('config')
                end

                nested(:ui) do
                  nested(:policies) do
                    required(:messages) { |val| !val.nil? }
                    required(:requests) { |val| !val.nil? }
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
