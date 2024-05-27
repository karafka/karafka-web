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
      module Ui
        module Lib
          # Search related contracts
          module Search
            # Namespace with search related contracts
            module Contracts
              # Makes sure, all the expected UI search config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load(
                    File.read(
                      File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                    )
                  ).fetch('en').fetch('validations').fetch('config')
                end

                nested(:ui) do
                  nested(:search) do
                    required(:matchers) { |val| val.is_a?(Array) && !val.empty? }

                    required(:timeout) { |val| val.is_a?(Integer) && val.positive? }

                    # Users can define their own search limits and we just make sure they do not
                    # do something weird like negative numbers
                    required(:limits) do |val|
                      next false unless val.is_a?(Array)
                      next false if val.empty?
                      next false unless val.all? { |count| count.is_a?(Integer) }
                      next false unless val.all?(&:positive?)

                      true
                    end
                  end
                end

                # Ensure all matchers respond to name and are callable
                virtual do |data, errors|
                  next unless errors.empty?

                  detected_errors = []

                  data.dig(:ui, :search, :matchers).each do |matcher|
                    next if matcher.respond_to?(:name) && matcher.public_method_defined?(:call)

                    detected_errors << [%i[ui search matchers], :must_have_name_and_call]
                  end

                  detected_errors
                end

                # Make sure that all matchers names are unique
                virtual do |data, errors|
                  next unless errors.empty?

                  names = data.dig(:ui, :search, :matchers).map(&:name)

                  next if names.uniq.size == names.size

                  [[%i[ui search matchers], :must_have_unique_names]]
                end

                # Make sure that all matchers names are strings and not empty
                virtual do |data, errors|
                  next unless errors.empty?

                  detected_errors = []

                  data.dig(:ui, :search, :matchers).map(&:name).each do |name|
                    next if name.is_a?(String) && !name.empty?

                    detected_errors << [%i[ui search matchers], :name_must_be_valid]

                    break
                  end

                  detected_errors
                end
              end
            end
          end
        end
      end
    end
  end
end
