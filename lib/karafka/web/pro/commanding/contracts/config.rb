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
      module Commanding
        # Commanding related contracts
        module Contracts
          # Makes sure, all the expected commanding config is defined as it should be
          class Config < ::Karafka::Contracts::Base
            configure do |config|
              config.error_messages = YAML.safe_load_file(
                File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
              ).fetch("en").fetch("validations").fetch("config")
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
