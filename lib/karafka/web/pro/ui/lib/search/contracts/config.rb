# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
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
                      next false unless val.all?(Integer)
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
